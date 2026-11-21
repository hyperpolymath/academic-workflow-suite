# AI at Work — Union Training Laboratory

An independent, source-linked **Vue 3 + Vite** training prototype for UK journalism-sector ordinary union members, with optional material for chapel representatives and branches. It reconciles NEC information/training/distribution duties with chapel meeting, bargaining, safeguards and escalation activities. Not an officially endorsed NUJ product.

## Running locally

```bash
npm install
npm run dev
```

For a deployable static site: `npm run build`. Publish the `dist/` folder as a public website using HTTPS. No member authentication is needed for the public course; do not upload private union material or confidential examples.

## Activities

Six scenario-based units with immediate feedback; six structured workplace worksheets; draft AI agreement studio; plain-text export; primary-source links. No account, analytics, cookies, remote fonts or back-end submission. Progress, notes and drafts are saved to the browser’s localStorage on this device, until erased via the course control or browser settings. This is not synchronised across devices and is visible to other people using the same browser profile. Exports are plaintext and remain under the user's control.

## Pre-publication checklist

- Obtain the union's permission and verify any official branding, positions and procedural guidance.
- Commission union legal review of consultation, industrial action, ballots and jurisdiction, especially ongoing 2026 changes.
- Verify every source and appoint an editorial maintainer and regular review date.
- Run automated axe-core accessibility checks; manually test keyboard-only operation, NVDA, VoiceOver, zoom at 200% and 400%, mobile reflow and colour contrast before asserting WCAG 2.2 AA compliance.
- Validate real members' learning outcomes and test scenarios with chapels, freelancers and union trainers.
- Add versioned policy documents and a proper public content-review workflow; confidential member-only material would require a separate authenticated service.
- Serve through TLS with CSP, secure headers and monitored dependency updates. Audit production dependencies. No personal data collection is required for this prototype.

## Important limitation

No backend login, server-side persistence, accessibility certification or production deployment is included. This is a functional pilot resource, not a completed official training service, formal certificate programme, model collective agreement or legal advice.

## Member-first functional release v0.2

- Public, independent, self-directed member course (not official NUJ content).
- Pass all six learning scenarios; progress is saved automatically in local browser storage.
- Finish a six-question practical member action plan and confirm understanding of negotiating demands versus legal rights.
- Export action plan and workbook without an account; erase saved data from the course interface.
- The agreement studio is an optional advanced activity, not the default member route.
- Run `npm run build` for a production build; test `dist/` in the browser before deployment.
