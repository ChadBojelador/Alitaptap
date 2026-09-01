const { app, ensureDatabase } = require('../server/server');

const legacyPaths = new Set(['login', 'signup', 'profile', 'logout']);

module.exports = async (req, res) => {
    const [pathname, query = ''] = req.url.split('?');
    const segments = pathname.split('/').filter(Boolean);

    if (segments[0] === 'api' && legacyPaths.has(segments[1])) {
        req.url = `/${segments.slice(1).join('/')}${query ? `?${query}` : ''}`;
    } else if (segments[0] === 'api' && segments[1] === 'auth') {
        req.url = `/auth/${segments.slice(2).join('/')}${query ? `?${query}` : ''}`;
    }

    try {
        await ensureDatabase();
        app(req, res);
    } catch (error) {
        console.error('Vercel function initialization failed:', error);
        res.status(500).json({ error: 'Database initialization failed' });
    }
};
