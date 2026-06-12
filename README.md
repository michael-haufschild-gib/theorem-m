# Unconditional hyperbolicity of the critical Laguerre family

This repository contains a machine-checked proof of one theorem:

> For every integer `d ≥ 1`, all `2d` complex zeros of the polynomial
> `Ψ_d` are real.

Here `Ψ_d` is an explicit deformation of the Laguerre polynomial
`L_d^(−1/2)` at its critical scaling: each coefficient is multiplied
by a moment `M_k` built from factorials and harmonic numbers. These
moments turn out to be the moment sequence of a concrete
compound-Poisson random variable, and the theorem says that averaging
the Laguerre polynomial against that randomness never pushes a zero
off the real line — at any degree.

The result is modest in scope but provably not an instance of the
classical universal hyperbolicity-preservation theorems: the sequence `M_k`
fails the Pólya–Schur multiplier criterion already on
`(w² − 1)²` (Section 6 of the paper — in fact no nondegenerate
moment sequence preserves hyperbolicity universally, by
Cauchy–Schwarz), so the preservation proved here is specific to this
family. The proof is elementary: real-variable arguments only, no
complex analysis. The whole argument is written up in a short paper
and, separately, verified end-to-end in Lean 4.

## If you came here from the paper

| You want | Where it is |
|---|---|
| The paper itself | [`docs/preprint/main.pdf`](docs/preprint/main.pdf) (LaTeX source next to it) |
| The formal statement | [`formal/TheoremM/CriticalData.lean`](formal/TheoremM/CriticalData.lean) — the theorem is named `theorem_M` (our internal working name for the result; the `aeval` variant is `theorem_M_aeval`) |
| The definitions of `Ψ_d`, `C_d`, `M_k` | [`formal/TheoremM/Defs.lean`](formal/TheoremM/Defs.lean) |
| The axiom check | [`scripts/check_axioms.sh`](scripts/check_axioms.sh) |
| The independent kernel re-check | [`scripts/check_nanoda.sh`](scripts/check_nanoda.sh) |
| The numerical sanity suite | [`scripts/theoremM_verify.py`](scripts/theoremM_verify.py) |

In Lean, the statement reads:

```lean
theorem theorem_M (d : ℕ) (hd : 1 ≤ d) :
    ∀ z ∈ ((Psi d).map (algebraMap ℝ ℂ)).roots, z.im = 0
```

The development compiles with zero `sorry`s and depends only on the
three axioms underlying all of mathlib (`propext`,
`Classical.choice`, `Quot.sound`). The compiled proof has also been
re-checked with [nanoda_lib](https://github.com/ammkrn/nanoda_lib),
an independent implementation of the Lean 4 kernel, via a
[lean4export](https://github.com/leanprover/lean4export) export. CI
repeats all of this on every push.

## Checking it yourself

You need [elan](https://github.com/leanprover/elan), the Lean
toolchain manager; everything else is pinned by the repository.

```sh
cd formal
lake exe cache get           # fetch precompiled mathlib (no compiling, a few minutes)
lake build                   # build and kernel-check the proof
../scripts/check_axioms.sh   # print the axiom report; fails on any deviation
../scripts/check_nanoda.sh   # re-check the export with the external kernel
```

There is also a verification script that needs no Lean at all — it
recomputes every identity and constant of the paper numerically
(mpmath) and re-confirms the conclusion for `d ≤ 300`:

```sh
python3 scripts/theoremM_verify.py
```

## How the proof goes

Three steps, all on the real line (Sections 2–4 of the paper):

1. **The moments are a compound-Poisson law.** The sequence `M_k` has
   ratio `(k − 1/2)·exp(γ − H_{k−1})`, which classical integral
   representations of the digamma function (Gauss, Frullani) match to
   an explicit Lévy measure. This gives the exact decomposition
   `Ψ_d(x) = p·C_d(x) + ∫ C_d(vx) dμ(v)` with atom `p = √(2/e)` and a
   positive remainder of mass `1 − p`.
2. **An energy inequality.** From the differential equation of `C_d`,
   the quantity `C_d² + C_d′²` is nondecreasing on `x ≥ 0`. At every
   critical point `c` of `C_d` this forces `|C_d(vc)| ≤ |C_d(c)|` for
   all `v ∈ [0,1]`.
3. **Sign counting.** Because `p > 1/2`, the two facts above make
   `Ψ_d` copy the alternating signs of `C_d` at its critical points;
   together with the sign at infinity that is `d` sign changes on
   `(0, ∞)`, mirrored by evenness — `2d` real zeros, which is all of
   them.

The Lean development follows the same route; the file names map onto
the steps (`Frullani`, `Binet`, `CPMeasure`, `Moments`, `MuBridge`,
`Capstone` for step 1; `Energy` for step 2; `Hermite`,
`CriticalData`, `SignCount` for step 3, with `Defs` and `Structure`
holding the definitions and basic facts).

## Authorship

The mathematics and the Lean formalization were developed by two AI
research agents — Claude (Anthropic) and GPT (OpenAI) — working under
the direction of Michael Haufschild, 2026. We are aware that
AI-produced mathematics warrants extra skepticism; that is precisely
why everything here is machine-checked, why the kernel check was
repeated with an independent kernel implementation, and why the
numerical suite re-derives the paper's claims from scratch. No claim
in this repository rests on trusting the authors. If you find an
error anyway — in the paper's prose, the code, or anything between —
please open an issue.

## License

MIT (see `LICENSE`). Depends on
[mathlib](https://github.com/leanprover-community/mathlib4)
(Apache 2.0).
