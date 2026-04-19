# MVP Scope (Hackathon)

## Problem Statement
Civilians submit local problems with location data. Students input a research idea. The system finds the closest mapped problems and suggests research titles when a problem is selected.

## In Scope (MVP)
1. Community report submission (`title`, `description`, `lat`, `lng`, optional image)
2. Map with multiple pinpoints for validated problems
3. Student idea input and semantic matching against problems
4. Ranked matched problem list
5. Problem detail screen with AI-generated research title suggestions

## Out of Scope (MVP)
- Full donation/payment flow
- Advanced moderation automation
- Multi-language model personalization

## Success Criteria
- At least 1 end-to-end flow: report -> pin -> student match -> title suggestions
- Median match response time < 3s (test dataset)
- Students can generate at least 3 relevant title suggestions per selected problem
