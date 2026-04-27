require('dotenv').config();
const express = require('express');
const session = require('express-session');
const passport = require('passport');
const LocalStrategy = require('passport-local').Strategy;
const GoogleStrategy = require('passport-google-oauth20').Strategy;
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const { body, param, validationResult } = require('express-validator');
const xss = require('xss');
const hpp = require('hpp');
const morgan = require('morgan');
const User = require('./models/User');
const Draft = require('./models/Draft');
const ChatHistory = require('./models/ChatHistory');
const sequelize = require('./db');
const cors = require('cors');
const { spawn } = require('child_process');
const path = require('path');
const SequelizeStore = require('connect-session-sequelize')(session.Store);

const JWT_SECRET = process.env.JWT_SECRET;
if (!JWT_SECRET) throw new Error('JWT_SECRET must be set in .env');
const APP_URL = process.env.APP_URL || 'http://localhost:3000';

const app = express();
const sessionStore = new SequelizeStore({ db: sequelize });

app.set('trust proxy', 1);

// --- SECURITY HEADERS ---
app.use(helmet({
    contentSecurityPolicy: {
        directives: {
            defaultSrc: ["'self'"],
            scriptSrc: ["'self'"],
            styleSrc: ["'self'", "'unsafe-inline'", 'https://fonts.googleapis.com'],
            imgSrc: ["'self'", 'data:', 'https:'],
            connectSrc: ["'self'", APP_URL],
            fontSrc: ["'self'", 'https://fonts.gstatic.com', 'https:'],
            objectSrc: ["'none'"],
            frameAncestors: ["'none'"],
        }
    },
    crossOriginEmbedderPolicy: false
}));

// --- REQUEST LOGGING ---
app.use(morgan('combined'));

// --- RATE LIMITERS ---
const globalLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 200,
    standardHeaders: true,
    legacyHeaders: false,
    message: { error: 'Too many requests, please try again later.' }
});
const authLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 10,
    message: { error: 'Too many login attempts, please try again in 15 minutes.' }
});
const apiLimiter = rateLimit({
    windowMs: 60 * 1000,
    max: 60,
    message: { error: 'API rate limit exceeded.' }
});
app.use(globalLimiter);

// --- 1. MIDDLEWARE STACK ---
app.use(cors({
    origin: (origin, callback) => {
        if (!origin) return callback(null, true);
        const allowed = [
            'http://localhost:5173',
            'http://192.168.254.111:5173',
            APP_URL,
            process.env.FRONTEND_URL
        ].filter(Boolean);
        if (allowed.includes(origin) || /^http:\/\/192\.168\./.test(origin)) {
            return callback(null, true);
        }
        callback(new Error('Not allowed by CORS'));
    },
    credentials: true
}));

app.use(express.json({ limit: '50kb' }));
app.use(express.urlencoded({ extended: true, limit: '50kb' }));
app.use(hpp());

app.use(session({
    secret: process.env.SESSION_SECRET || 'keyboard_cat_random_secret',
    resave: false,
    saveUninitialized: false,
    store: sessionStore,
    cookie: { 
        secure: 'auto',
        httpOnly: true,
        sameSite: 'lax',
        maxAge: 24 * 60 * 60 * 1000 
    }
}));

sessionStore.sync();

app.use(passport.initialize());
app.use(passport.session());

// --- 2. PASSPORT SERIALIZATION ---
passport.serializeUser((user, done) => done(null, user.id));
passport.deserializeUser(async (id, done) => {
    try {
        const user = await User.findByPk(id);
        done(null, user);
    } catch (err) { done(err); }
});

// --- 3. STRATEGIES ---
passport.use(new LocalStrategy({ usernameField: 'email' }, async (email, password, done) => {
    try {
        const user = await User.findOne({ where: { email } });
        if (!user) return done(null, false, { message: 'User not found' });
        const isMatch = await bcrypt.compare(password, user.password);
        return isMatch ? done(null, user) : done(null, false, { message: 'Wrong password' });
    } catch (err) { return done(err); }
}));

// Google OAuth — only register if credentials are configured
if (process.env.GOOGLE_CLIENT_ID && process.env.GOOGLE_CLIENT_SECRET) {
passport.use(new GoogleStrategy({
    clientID: process.env.GOOGLE_CLIENT_ID,
    clientSecret: process.env.GOOGLE_CLIENT_SECRET,
    callbackURL: process.env.GOOGLE_CALLBACK_URL || `${APP_URL}/auth/google/callback`
  },
  async (accessToken, refreshToken, profile, done) => {
    try {
        let user = await User.findOne({ where: { googleId: profile.id } });
        if (!user) {
            user = await User.create({
                googleId: profile.id,
                displayName: profile.displayName,
                email: profile.emails[0].value
            });
        }
        return done(null, user);
    } catch (err) { return done(err); }
  }
));
}

// JWT auth middleware — checks Authorization header first, falls back to session
const authMiddleware = async (req, res, next) => {
    const authHeader = req.headers['authorization'];
    if (authHeader?.startsWith('Bearer ')) {
        try {
            const payload = jwt.verify(authHeader.slice(7), JWT_SECRET);
            req.user = await User.findByPk(payload.id);
            return next();
        } catch { return res.status(401).json({ message: 'Invalid token' }); }
    }
    // fallback to passport session (Google OAuth)
    if (req.isAuthenticated()) return next();
    return res.status(401).json({ message: 'Not logged in' });
};

// --- VALIDATION HELPER ---
const validate = (req, res, next) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return res.status(422).json({ errors: errors.array() });
    next();
};

// Auth Routes
app.post('/signup',
    authLimiter,
    [
        body('email').isEmail().normalizeEmail().withMessage('Valid email required'),
        body('password')
            .isLength({ min: 8 }).withMessage('Password must be at least 8 characters')
            .matches(/[A-Z]/).withMessage('Password must contain an uppercase letter')
            .matches(/[0-9]/).withMessage('Password must contain a number')
    ],
    validate,
    async (req, res) => {
        try {
            const existing = await User.findOne({ where: { email: req.body.email } });
            if (existing) return res.status(409).json({ error: 'Email already in use' });
            const hashedPassword = await bcrypt.hash(req.body.password, 12);
            await User.create({ email: req.body.email, password: hashedPassword, displayName: xss(req.body.displayName || ''), agreedToTerms: true });
            res.status(201).json({ message: 'User created' });
        } catch (err) { res.status(500).json({ error: 'Error creating user' }); }
    }
);

app.post('/login',
    authLimiter,
    [
        body('email').isEmail().normalizeEmail(),
        body('password').notEmpty()
    ],
    validate,
    (req, res, next) => {
        passport.authenticate('local', (err, user) => {
            if (err || !user) return res.status(401).json({ error: 'Invalid credentials' });
            const token = jwt.sign({ id: user.id }, JWT_SECRET, { expiresIn: '7d' });
            res.json({ token, user: { id: user.id, email: user.email, displayName: user.displayName, persona: user.persona } });
        })(req, res, next);
    }
);

const { v4: uuidv4 } = require('uuid');

// --- Chat Session Routes ---
// List all sessions for user
app.get('/api/chat/sessions', authMiddleware, apiLimiter, async (req, res) => {
    try {
        const sessions = await ChatHistory.findAll({
            where: { userId: req.user.id },
            attributes: ['sessionId', 'title', 'updatedAt'],
            order: [['updatedAt', 'DESC']]
        });
        res.json(sessions);
    } catch (err) { res.status(500).json({ error: err.message }); }
});

// Get one session's messages
app.get('/api/chat/sessions/:sessionId', authMiddleware, apiLimiter,
    [param('sessionId').isUUID().withMessage('Invalid session ID')],
    validate,
    async (req, res) => {
    try {
        const record = await ChatHistory.findOne({ where: { sessionId: req.params.sessionId, userId: req.user.id } });
        if (!record) return res.status(404).json({ error: 'Not found' });
        res.json({ messages: JSON.parse(record.messages) });
    } catch (err) { res.status(500).json({ error: err.message }); }
});

// Create new session
app.post('/api/chat/sessions', authMiddleware, apiLimiter,
    [body('title').optional().isString().trim().isLength({ max: 200 })],
    validate,
    async (req, res) => {
        try {
            const { sessionId, title, messages } = req.body;
            const record = await ChatHistory.create({
                sessionId: sessionId || uuidv4(),
                userId: req.user.id,
                title: xss(title || 'New Chat'),
                messages: JSON.stringify(messages || [])
            });
            res.json({ sessionId: record.sessionId });
        } catch (err) { res.status(500).json({ error: 'Failed to create session' }); }
    }
);

// Update session messages + title
app.put('/api/chat/sessions/:sessionId', authMiddleware, apiLimiter,
    [
        param('sessionId').isUUID(),
        body('title').optional().isString().trim().isLength({ max: 200 })
    ],
    validate,
    async (req, res) => {
        try {
            const { messages, title } = req.body;
            const record = await ChatHistory.findOne({ where: { sessionId: req.params.sessionId, userId: req.user.id } });
            if (!record) return res.status(404).json({ error: 'Not found' });
            await record.update({ messages: JSON.stringify(messages), ...(title && { title: xss(title) }) });
            res.json({ ok: true });
        } catch (err) { res.status(500).json({ error: 'Failed to update session' }); }
    }
);

// Delete a session
app.delete('/api/chat/sessions/:sessionId', authMiddleware, apiLimiter,
    [param('sessionId').isUUID()],
    validate,
    async (req, res) => {
        try {
            await ChatHistory.destroy({ where: { sessionId: req.params.sessionId, userId: req.user.id } });
            res.json({ ok: true });
        } catch (err) { res.status(500).json({ error: 'Failed to delete session' }); }
    }
);

// --- Chat with IThink (Python ADK + Groq) ---
app.post('/api/chat', authMiddleware, apiLimiter,
    [body('message').isString().trim().isLength({ min: 1, max: 5000 }).withMessage('Message must be 1–5000 characters')],
    validate,
    (req, res) => {
        const message = xss(req.body.message);

    const scriptPath = path.join(__dirname, 'credibility_checker', 'chat_agent.py');
    const pythonCmd = process.platform === 'win32' ? 'python' : 'python3';
    const python = spawn(pythonCmd, ['-u', scriptPath], { env: { ...process.env } });

    let output = '';
    let errorOutput = '';
    python.stdout.on('data', (data) => { output += data.toString(); });
    python.stderr.on('data', (data) => { errorOutput += data.toString(); });

    python.stdin.write(JSON.stringify({ message }));
    python.stdin.end();

    python.on('close', () => {
        try {
            const jsonStart = output.indexOf('{');
            const jsonEnd = output.lastIndexOf('}') + 1;
            const data = JSON.parse(output.substring(jsonStart, jsonEnd));
            if (data.error) return res.status(500).json({ error: data.error });
            res.json({ reply: data.reply });
        } catch (err) {
            console.error('chat_agent stderr:', errorOutput);
            res.status(500).json({ error: 'Failed to parse chat response', raw: output.slice(0, 300) });
        }
    });
});

// --- NEW: Credibility API (Python Integration) ---
app.post('/api/credibility', authMiddleware, apiLimiter,
    [body('text').isString().trim().isLength({ min: 1, max: 20000 })],
    validate,
    (req, res) => {
        const { text, persona } = req.body;

        const scriptPath = path.join(__dirname, 'credibility_checker', 'agent.py');
        const pythonCmd = process.platform === 'win32' ? 'python' : 'python3';

        const python = spawn(pythonCmd, ['-u', scriptPath], {
            env: { ...process.env }
        });

        let output = '';
        let errorOutput = '';

        python.stdout.on('data', (data) => {
            output += data.toString();
        });

        python.stderr.on('data', (data) => {
            errorOutput += data.toString();
        });

        python.stdin.write(JSON.stringify({ text, persona: persona || '1' }));
        python.stdin.end();

        python.on('close', (code) => {

            // 🔴 ADD THIS
            if (code !== 0) {
                console.error('Python crashed:', errorOutput);
                return res.status(500).json({
                    error: 'Python process failed',
                    details: errorOutput
                });
            }

            try {
                const jsonStart = output.indexOf('{');
                const jsonEnd = output.lastIndexOf('}') + 1;

                if (jsonStart === -1 || jsonEnd === -1) {
                    throw new Error("No JSON found in output");
                }

                const data = JSON.parse(output.substring(jsonStart, jsonEnd));

                res.json(data);

            } catch (err) {
                console.error('Parse error:', err);
                console.error('Raw output:', output);
                console.error('Stderr:', errorOutput);

                res.status(500).json({
                    error: 'Invalid JSON from Python',
                    raw: output,
                    stderr: errorOutput
                });
            }
        });
    }
);

app.post('/api/user/agree-terms', authMiddleware, apiLimiter, async (req, res) => {
    try {
        await req.user.update({ agreedToTerms: true });
        res.json({ ok: true });
    } catch (err) { res.status(500).json({ error: 'Failed to update' }); }
});

// Update profile
app.put('/api/user/profile', authMiddleware, apiLimiter,
    [
        body('displayName').optional().isString().trim().isLength({ max: 100 }),
        body('bio').optional().isString().trim().isLength({ max: 500 }),
        body('institution').optional().isString().trim().isLength({ max: 200 }),
        body('location').optional().isString().trim().isLength({ max: 100 }),
        body('avatarUrl').optional().isString().isLength({ max: 2000 }),
    ],
    validate,
    async (req, res) => {
        try {
            const { displayName, bio, institution, location, avatarUrl } = req.body;
            await req.user.update({
                ...(displayName !== undefined && { displayName: xss(displayName) }),
                ...(bio !== undefined && { bio: xss(bio) }),
                ...(institution !== undefined && { institution: xss(institution) }),
                ...(location !== undefined && { location: xss(location) }),
                ...(avatarUrl !== undefined && { avatarUrl }),
            });
            res.json({ user: req.user });
        } catch (err) { res.status(500).json({ error: 'Failed to update profile' }); }
    }
);

// Generate QR login token
app.get('/api/user/qr-token', authMiddleware, apiLimiter, async (req, res) => {
    try {
        const qrToken = jwt.sign({ id: req.user.id, qr: true }, JWT_SECRET, { expiresIn: '5m' });
        res.json({ qrToken, expiresIn: 300 });
    } catch (err) { res.status(500).json({ error: 'Failed to generate QR token' }); }
});

// Verify QR token and return auth token
app.post('/api/auth/qr-verify', async (req, res) => {
    try {
        const { qrToken } = req.body;
        const payload = jwt.verify(qrToken, JWT_SECRET);
        if (!payload.qr) return res.status(400).json({ error: 'Invalid QR token' });
        const user = await User.findByPk(payload.id);
        if (!user) return res.status(404).json({ error: 'User not found' });
        const token = jwt.sign({ id: user.id }, JWT_SECRET, { expiresIn: '7d' });
        res.json({ token, user: { id: user.id, email: user.email, displayName: user.displayName } });
    } catch (err) { res.status(401).json({ error: 'QR token expired or invalid' }); }
});

app.put('/api/user/persona', authMiddleware, apiLimiter,
    [body('persona').isString().trim().isIn(['1','2','3','4','5']).withMessage('Invalid persona')],
    validate,
    async (req, res) => {
        try {
            await req.user.update({ persona: req.body.persona });
            res.json({ persona: req.user.persona });
        } catch (err) { res.status(500).json({ error: 'Failed to update persona' }); }
    }
);

app.delete('/api/user', authMiddleware, apiLimiter, async (req, res) => {
    try {
        const userId = req.user.id;
        await Draft.destroy({ where: { userId } });
        await ChatHistory.destroy({ where: { userId } });
        await req.user.destroy();
        res.json({ ok: true });
    } catch (err) { res.status(500).json({ error: err.message }); }
});

// --- Draft Routes ---
app.post('/api/drafts', authMiddleware, apiLimiter,
    [
        body('title').optional().isString().trim().isLength({ max: 500 }),
        body('content').optional().isString().isLength({ max: 100000 })
    ],
    validate,
    async (req, res) => {
        const { title, content, analysis } = req.body;
        try {
            const draft = await Draft.create({
                title: xss(title || 'Untitled Document'),
                content: content || '',
                analysis: analysis ? JSON.stringify(analysis) : null,
                userId: req.user.id
            });
            res.json(draft);
        } catch (err) { res.status(500).json({ error: 'Failed to create draft' }); }
    }
);

app.get('/api/drafts/trash', authMiddleware, async (req, res) => {
    try {
        const { Op } = require('sequelize');
        const drafts = await Draft.findAll({ where: { userId: req.user.id, deletedAt: { [Op.not]: null } }, order: [['deletedAt', 'DESC']] });
        res.json(drafts);
    } catch (err) { res.status(500).json({ error: err.message }); }
});

app.get('/api/drafts', authMiddleware, async (req, res) => {
    try {
        const drafts = await Draft.findAll({ where: { userId: req.user.id, deletedAt: null }, order: [['updatedAt', 'DESC']] });
        res.json(drafts);
    } catch (err) { res.status(500).json({ error: err.message }); }
});

app.get('/api/drafts/:id', authMiddleware, async (req, res) => {
    try {
        const draft = await Draft.findOne({ where: { id: req.params.id, userId: req.user.id } });
        if (!draft) return res.status(404).json({ message: 'Draft not found' });
        const plain = draft.get({ plain: true });
        if (plain.analysis) plain.analysis = JSON.parse(plain.analysis);
        res.json(plain);
    } catch (err) { res.status(500).json({ error: err.message }); }
});

app.put('/api/drafts/:id', authMiddleware, apiLimiter,
    [
        param('id').isInt(),
        body('title').optional().isString().trim().isLength({ max: 500 }),
        body('content').optional().isString().isLength({ max: 100000 })
    ],
    validate,
    async (req, res) => {
        try {
            const draft = await Draft.findOne({ where: { id: req.params.id, userId: req.user.id } });
            const { title, content, analysis } = req.body;
            if (!draft) return res.status(404).json({ message: 'Draft not found' });
            await draft.update({ title: xss(title || draft.title), content: content || '', analysis: analysis ? JSON.stringify(analysis) : null });
            res.json(draft);
        } catch (err) { res.status(500).json({ error: 'Failed to update draft' }); }
    }
);

app.delete('/api/drafts/:id', authMiddleware, async (req, res) => {
    try {
        const draft = await Draft.findOne({ where: { id: req.params.id, userId: req.user.id } });
        if (!draft) return res.status(404).json({ message: 'Draft not found' });
        await draft.update({ deletedAt: new Date() });
        res.json({ message: 'Moved to trash' });
    } catch (err) { res.status(500).json({ error: err.message }); }
});

app.post('/api/drafts/:id/restore', authMiddleware, async (req, res) => {
    try {
        const draft = await Draft.findOne({ where: { id: req.params.id, userId: req.user.id } });
        if (!draft) return res.status(404).json({ message: 'Draft not found' });
        await draft.update({ deletedAt: null });
        res.json({ message: 'Restored' });
    } catch (err) { res.status(500).json({ error: err.message }); }
});

app.delete('/api/drafts/:id/permanent', authMiddleware, async (req, res) => {
    try {
        const draft = await Draft.findOne({ where: { id: req.params.id, userId: req.user.id } });
        if (!draft) return res.status(404).json({ message: 'Draft not found' });
        await draft.destroy();
        res.json({ message: 'Permanently deleted' });
    } catch (err) { res.status(500).json({ error: err.message }); }
});

// Google Redirects
app.get('/auth/google', (req, res, next) => {
    req.session.authOrigin = process.env.FRONTEND_URL || APP_URL;
    req.session.save(() => passport.authenticate('google', { scope: ['profile', 'email'] })(req, res, next));
});

app.get('/auth/google/callback', (req, res, next) => {
    passport.authenticate('google', (err, user) => {
        const origin = req.session.authOrigin || process.env.FRONTEND_URL;
        if (err || !user) return res.redirect(`${origin}/login`);
        const token = jwt.sign({ id: user.id }, JWT_SECRET, { expiresIn: '7d' });
        res.redirect(`${origin}/auth/callback?token=${token}`);
    })(req, res, next);
});

app.get('/profile', authMiddleware, (req, res) => {
    res.json({ user: req.user });
});

app.get('/logout', (req, res, next) => {
    req.logout((err) => {
        if (err) return next(err);
        res.clearCookie('connect.sid'); 
        res.send("Logged out successfully");
    });
});

// Health check
app.get('/', (req, res) => res.json({ status: 'IThink API running' }));

// --- GLOBAL ERROR HANDLER ---
// eslint-disable-next-line no-unused-vars
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(err.status || 500).json({ error: 'Something went wrong' });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 Server running on port ${PORT}`);
    sequelize.sync({ alter: true })
        .then(() => console.log('✅ DB synced'))
        .catch(err => console.error('⚠️ DB sync failed:', err.message));
});