const PLAN_SYSTEM_PROMPT = `You are an AI project planner for ALITAPTAP, a platform that connects community problems to student research aligned with the UN SDGs.

Return exactly one JSON object with these keys: title, problem, features (five strings), plan (five objects with step, title, desc), tech_stack (frontend, backend, database, ai), folder_structure, starter_code, and sdg. Do not use Markdown fences or add text outside the JSON.`;

const PERSONAS = {
    '1': { name: 'High School Student', voice: 'Casual, relatable, easy to understand.' },
    '2': { name: 'College Student', voice: 'Analytical, structured, academic.' },
    '3': { name: 'Professional', voice: 'Meticulous, expert, formal tone.' },
};

async function groq(messages, maxTokens = 2500) {
    if (!process.env.GROQ_API_KEY) {
        throw new Error('GROQ_API_KEY is not configured');
    }

    const response = await fetch('https://api.groq.com/openai/v1/chat/completions', {
        method: 'POST',
        headers: {
            Authorization: `Bearer ${process.env.GROQ_API_KEY}`,
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({
            model: 'llama-3.3-70b-versatile',
            messages,
            temperature: 0.7,
            max_tokens: maxTokens,
        }),
    });

    if (!response.ok) throw new Error(`Groq returned ${response.status}`);

    const payload = await response.json();
    const content = payload.choices?.[0]?.message?.content?.trim();
    if (!content) throw new Error('Groq returned no message content');
    return content;
}

async function chat(message) {
    return groq([
        { role: 'system', content: PLAN_SYSTEM_PROMPT },
        { role: 'user', content: message },
    ]);
}

async function searchUrls(query) {
    if (!process.env.SERPER_API_KEY) return [];
    try {
        const response = await fetch('https://google.serper.dev/search', {
            method: 'POST',
            headers: { 'X-API-KEY': process.env.SERPER_API_KEY, 'Content-Type': 'application/json' },
            body: JSON.stringify({ q: query, num: 3 }),
        });
        if (!response.ok) return [];
        const payload = await response.json();
        return (payload.organic || []).slice(0, 3).map((result) => result.link).filter(Boolean);
    } catch {
        return [];
    }
}

function jsonFromModel(content) {
    const start = content.indexOf('{');
    const end = content.lastIndexOf('}');
    if (start < 0 || end < start) throw new Error('AI response did not contain JSON');
    return JSON.parse(content.slice(start, end + 1));
}

async function checkCredibility(text, personaIndex) {
    const persona = PERSONAS[personaIndex] || PERSONAS['1'];
    const urls = await searchUrls(text);
    const urlContext = urls.length ? urls.join('\n') : 'No search results available.';
    const content = await groq([
        {
            role: 'system',
            content: `You are a ${persona.name}. Tone: ${persona.voice}\n\nReal source URLs (use only these; never invent URLs):\n${urlContext}\n\nAnalyze the supplied text. Return only JSON with: overall_credibility_score (number), summary (string), apa_summary (string), findings (three objects: claim, accuracy_percentage, analysis, source_url), and suggestions (three objects: text, url). If no URLs are available, use an empty string for source_url and url.`,
        },
        { role: 'user', content: text },
    ], 2000);
    const result = jsonFromModel(content);
    if (Array.isArray(result.findings) && result.findings.length) {
        result.overall_credibility_score = Math.round(result.findings.reduce(
            (total, finding) => total + Number(finding.accuracy_percentage || 0), 0,
        ) / result.findings.length);
    }
    return result;
}

module.exports = { chat, checkCredibility };
