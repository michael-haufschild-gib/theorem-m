# Theorem M — a formally verified hyperbolicity theorem

**Status: PROVEN.** Kernel-checked in Lean 4 (v4.30.0) against pinned
mathlib, with **zero `sorry`s** and only the three standard axioms:

```
'TheoremM.theorem_M' depends on axioms: [propext, Classical.choice, Quot.sound]
```

## Statement

For every integer `d ≥ 1`, **all complex zeros of `Ψ_d` are real**, where

```
Ψ_d(w) = Σ_{k=0}^{d}  (−1)^k · (d)_k · M_k / (d^k · (2k)!) · w^{2k}
```

with `(d)_k` the falling factorial, and the moment sequence

```
M_k = (2k)! · exp(γ·k − S₁(k)) / (4^k · k!),     S₁(k) = k·H_{k−1} − (k−1)
```

(`γ` = Euler–Mascheroni, `H_k` = harmonic number). In Lean:

```lean
theorem theorem_M (d : ℕ) (hd : 1 ≤ d) :
    ∀ z ∈ ((Psi d).map (algebraMap ℝ ℂ)).roots, z.im = 0
```

(`formal/TheoremM/CriticalData.lean`, with the `aeval` companion
`theorem_M_aeval`.)

## Scope — read this first

**Theorem M does not prove the Riemann Hypothesis.** It establishes
hyperbolicity of the critical-model polynomials `Ψ_d` at every finite
`d`. Its relevance to RH runs through a separate, *unproven* transport
program (the W2′/ξ-limit interface); see the manuscript §5 for the open
items. No claim beyond the formal statement above is made here.

## Verify it yourself

Requires [elan](https://github.com/leanprover/elan) (Lean toolchain
manager); the toolchain version is pinned by `formal/lean-toolchain`.

```sh
cd formal
lake exe cache get      # fetch precompiled mathlib (~minutes, no compile)
lake build              # builds and kernel-checks the full tree
../scripts/check_axioms.sh   # prints the axiom report; fails on any deviation
../scripts/check_nanoda.sh   # exports theorem_M/theorem_M_aeval and checks them with nanoda_lib
```

The numerical pre-certification suite (independent of Lean; mpmath/scipy):

```sh
python3 scripts/theoremM_verify.py
```

## Proof architecture

The proof is a real-variable sign-alternation argument — no complex
analysis on the critical path:

1. **Frullani + integer Binet** (`Frullani.lean`, `Binet.lean`) — the
   integral representation behind the moment sequence.
2. **Compound-Poisson measure** (`CPMeasure.lean`) — a Lévy measure with
   atom mass `−log p`, `p = √(2/e)`; its exponential moments ARE `M_k`;
   the residual pushforward `μ` lives on `(0,1]` with even moments
   `M_k − p`.
3. **Decomposition + budget** (`MuBridge.lean`, `Capstone.lean`) —
   `Ψ_d(x) = p·C_d(x) + ∫ C_d(vx) dμ(v)` and the strict budget
   `1 − p < p`, transferring the sign of `C_d` at its critical points
   to `Ψ_d`.
4. **Hermite critical data** (`Hermite.lean`, `CriticalData.lean`) —
   `C_d` is a scaled Hermite polynomial; all Hermite roots are real and
   simple with interlacing, giving `d` critical points of `C_d` with
   alternating critical-value signs.
5. **Sign-count assembly** (`SignCount.lean`) — alternation forces `2d`
   real roots; degree `2d` pins them all.

| Module | Content |
|--------|---------|
| `Defs.lean` | `S1`, `M`, `Cpoly`, `Psi`; coefficient identities |
| `Structure.lean` | degree, parity, leading-coefficient facts |
| `Energy.lean` | real W1: `abs_Cpoly_le_of_critical` |
| `Hermite.lean` | Hermite polynomials: splits, simple roots, interlacing, root counting |
| `SignCount.lean` | `psi_roots_real_of_alternation` |
| `MuBridge.lean` | `pAtom`, sign-transfer core `Psi_sign_of_budget` |
| `Moments.lean`, `MomentsLimit.lean` | moment algebra and limits |
| `Frullani.lean`, `Binet.lean` | integral representations |
| `CPMeasure.lean` | the compound-Poisson construction |
| `Capstone.lean` | `theorem_M_of_critical_data_measure` |
| `CriticalData.lean` | critical data of `C_d`; **`theorem_M`** |

## Documents

- `docs/theorem_M_draft.md` — the human-readable manuscript (statement,
  proofs, constants, referee rounds, formalization status).
- `formal/FORMALIZATION_PLAN.md` — the phase-by-phase formalization
  campaign log.

## Authorship

Developed by two AI research agents — Claude (Anthropic) and GPT
(OpenAI) — working as a coordinated pair under the direction of
Michael Haufschild, 2026. The Lean kernel is the referee: no claim in
`formal/` rests on trusting the authors.

## License

MIT (see `LICENSE`). Depends on [mathlib](https://github.com/leanprover-community/mathlib4)
(Apache 2.0).
