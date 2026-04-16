---
name: aesthetic
effort: xhigh
disable-model-invocation: true
argument-hint: <what to build>
description: Generate distinctive, polished frontends — not AI slop
---

# Aesthetic Frontend

Generate frontends that look genuinely designed, not AI-generated. Fight the convergence toward generic purple-gradient-on-white blandness.

## Rules

Apply these to ALL frontend generation in this session:

<frontend_aesthetics>
You tend to converge toward generic, "on distribution" outputs. In frontend design, this creates what users call the "AI slop" aesthetic. Avoid this: make creative, distinctive frontends that surprise and delight. Focus on:

Typography: Choose fonts that are beautiful, unique, and interesting. Avoid generic fonts like Arial and Inter; opt instead for distinctive choices that elevate the frontend's aesthetics.

Color & Theme: Commit to a cohesive aesthetic. Use CSS variables for consistency. Dominant colors with sharp accents outperform timid, evenly-distributed palettes. Draw from IDE themes and cultural aesthetics for inspiration.

Motion: Use animations for effects and micro-interactions. Prioritize CSS-only solutions for HTML. Use Motion library for React when available. Focus on high-impact moments: one well-orchestrated page load with staggered reveals (animation-delay) creates more delight than scattered micro-interactions.

Backgrounds: Create atmosphere and depth rather than defaulting to solid colors. Layer CSS gradients, use geometric patterns, or add contextual effects that match the overall aesthetic.

Avoid generic AI-generated aesthetics:
- Overused font families (Inter, Roboto, Arial, system fonts)
- Clichéd color schemes (particularly purple gradients on white backgrounds)
- Predictable layouts and component patterns
- Cookie-cutter design that lacks context-specific character

Interpret creatively and make unexpected choices that feel genuinely designed for the context. Vary between light and dark themes, different fonts, different aesthetics. You still tend to converge on common choices (Space Grotesk, for example) across generations. Avoid this: it is critical that you think outside the box!
</frontend_aesthetics>

## Font Reference

Don't just pick randomly. Match font to context:

| Vibe | Fonts |
|------|-------|
| Code | JetBrains Mono, Fira Code, Space Grotesk |
| Editorial | Playfair Display, Crimson Pro, Fraunces |
| Startup | Clash Display, Satoshi, Cabinet Grotesk |
| Technical | IBM Plex family, Source Sans 3 |
| Distinctive | Bricolage Grotesque, Obviously, Newsreader |

**Pairing:** High contrast = interesting. Display + monospace, serif + geometric sans. Use weight extremes (100/200 vs 800/900, not 400 vs 600). Size jumps of 3x+, not 1.5x. Load from Google Fonts.

## Flow

1. Read the request: $ARGUMENTS
2. Before coding, state your aesthetic choices: font, palette, theme direction, one animation idea
3. Build it — single self-contained HTML file with inline CSS/JS unless the project requires otherwise
4. Save variants to the `variants/` folder in the project root (create if needed). Use descriptive filenames (e.g., `variants/async_jobs_mission_control.html`)
5. Use Tailwind from CDN if vanilla HTML. Respect project's existing stack if there is one.
6. Open in browser for review if applicable

## What "good" looks like

- Has a point of view. Not "clean and modern" — that's nothing.
- Color palette has a dominant + accent, not 5 equally-weighted colors
- One signature animation moment, not sprinkles everywhere
- Typography that you'd actually notice
- Background has depth — gradients, patterns, texture — not flat white
