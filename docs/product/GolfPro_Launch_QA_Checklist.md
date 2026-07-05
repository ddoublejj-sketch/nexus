# Golf Pro Launch QA Checklist

Date: 2026-07-05

This checklist is the Phase 9 compact launch note for the MVP branch. It is not a live-publish approval.

## Smoke Areas

- Practice range starts and accepts server-owned shots.
- 18-hole Pinebrook solo stroke path starts, advances holes, completes, and emits result payloads.
- Ball, club, tracer, landing marker, and HUD shot stats render from server-owned shot results.
- Party/private stroke path starts through local private-match transport.
- 2v2 scramble core starts, accepts ball selection, and keeps ranked scramble disabled.
- Records update only from valid ranked 18-hole server results.
- Leaderboard rows are written only by valid ranked 18-hole server results.
- Mystery Range rewards come from server-owned practice target hits and full-meter deposits only.
- Locker equip rejects unowned cosmetics and does not alter club stats.
- Tournament page shows Weekend Open, attempts, cosmetic reward, and leaderboard rows.

## Audit Statements

- No live publish is authorized by this checklist.
- No OpenAI/API-cost feature is required or added for MVP gameplay.
- Tournament rewards remain deterministic and cosmetic-only.
- Runtime source must not include protected real-course, protected tournament, gambling, cash, Robux, paid random reward, or pay-to-win shipping strings.
- Pinebrook National remains an original fictional course and must not use Google-derived course geometry.