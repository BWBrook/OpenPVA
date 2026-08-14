# Goal 007 - Pedigree ancestry foundation

## Objective

Replace the ambiguous marker-derived `F` surface with an optional, exact,
in-memory pedigree foundation. Pedigree inbreeding is the probability of
identity by descent conditional on the recorded pedigree and an explicitly
declared unrelated, non-inbred founder base; it is not observed marker
heterozygosity.

## Scientific target and scope of inference

The target quantity for individual `i` is `pedigree_F[i]`, the probability
that its two alleles at a randomly chosen autosomal locus are IBD conditional
on the complete recorded parent graph and founder-base declaration. Using the
numerator relationship matrix convention, `A[i,i] = 1 + pedigree_F[i]`,
`A[i,j] = (A[sire(i),j] + A[dam(i),j]) / 2`, and a newborn's
`pedigree_F = A[mother,father] / 2`. OpenPVA does not infer the unrecorded
pedigree, genomic IBD, allele frequencies, fitness effects or population-wide
kinship management.

## Required outcomes

1. Pedigree is optional. Once enabled, every persistent record explicitly has
   `pedigree_status` equal to `base_founder` or `known_parentage`, plus a
   finite numeric `pedigree_F` in `[0, 1]`.
2. A base founder has both parent IDs missing and is assumed unrelated and
   non-inbred at the declared pedigree horizon. Known parentage has two
   distinct, earlier persistent parents: a female mother and male father.
   Missing, partial, uncertain, nonexistent, later, self, cyclic or otherwise
   ambiguous parentage fails before state mutation. Dead ancestors remain
   valid because records are append-only.
3. Production ancestry uses exact ancestor tracing through a linear-size
   parent/F/Mendelian-sampling index. It never stores a persistent quadratic
   relationship matrix and never confuses public IDs with row positions.
4. Initial populations, newborns and introductions use ordinary public helpers
   that compose through existing creator callbacks and exact field
   declarations. Introductions are explicit base founders or reference two
   ancestors already in the shared pre-process state; same-batch related
   ancestry is unsupported.
5. A tidy pedigree ledger and essential summaries are public. Marker alleles,
   marker-derived `F`/`Fhat`, and an inbreeding-fitness response are absent.
6. The generic engine, controller-free process seam, allocator, accounting and
   population ledger remain authoritative and unchanged in meaning.

## Acceptance evidence

- Independent dense-tabular `A` oracle checks the factor-of-two convention and
  hand pedigrees: unrelated founders and offspring 0; half-sib mating 0.125;
  full-sib and parent-offspring mating 0.25; first-cousin mating 0.0625.
- Failure tests cover duplicate, missing, later, self and same parent IDs;
  parent sex, cycles/topology, partial/ambiguous parentage, missing pedigree
  fields, invalid or inconsistent status/F, and incomplete creators.
- Integration covers founder initialisation, multiple birth generations,
  founder and known-parentage introductions, same-pre-state semantics, dead
  ancestors, downstream consumption, append-only IDs, preflight, accounting,
  repeatability, serial/fork identity and independence from arbitrary marker
  attributes.
- Many small valid generated pedigrees match the independent dense oracle.
  One declared larger-pedigree run records elapsed time and linear persistent
  ancestry-vector size without introducing a benchmark framework.
- Focused and retained tests, isolated R 4.6.1 build/check, diff and surface
  scans pass. The known `renv` advisory is not reconciled.

## Non-goals

Database or file persistence, checkpoints, a second population representation,
marker loci or transmission, mutation/recombination/linkage, realised/genomic
IBD, founder groups or metafounders, uncertain/partial parentage, mate ranking,
mean-kinship management, inbreeding depression, empirical genetics,
YAML/targets/Quarto reconnection, compatibility layers and engine redesign.

## Publication boundary

No staging, commit, push, tag, release or publication is authorised.
