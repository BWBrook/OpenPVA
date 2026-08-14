# Pedigree ancestry contract

## Scientific target

For each pedigree-enabled individual, `pedigree_F` is the probability that its
two alleles at a randomly chosen autosomal locus are identical by descent,
conditional on the complete recorded pedigree and declared founder horizon.
It is not observed heterozygosity, genomic IBD or an estimate of a fitness
effect.

The numerical convention is the numerator relationship matrix `A`:

```text
A[i,i] = 1 + pedigree_F[i]
A[i,j] = (A[mother(i),j] + A[father(i),j]) / 2
pedigree_F[newborn] = A[mother,father] / 2
```

The final division by two is essential: `A[mother,father]` is twice parental
kinship.

## Optional but complete state

Pedigree is enabled when any population record exposes `pedigree_status` or
`pedigree_F`. It is then complete across the append-only ledger. Each record
declares exactly one status:

- `base_founder`: both parent IDs are absent; the individual is assumed
  unrelated and non-inbred relative to the declared horizon;
- `known_parentage`: both parent IDs identify distinct earlier records, with a
  female mother and male father under the existing `F`/`M` sex contract.

Partially known or uncertain parentage, phantom parents, selfing, same-parent
roles, later references and cyclic topology fail. Parent IDs are persistent
public IDs, never row numbers. A local derived map connects IDs to ledger rows
for calculation only. Dead ancestors remain available because death changes
`alive` rather than deleting records.

## Exact linear-memory calculation

Production uses the exact decomposition `A = T D T'`. `T` contributions for a
queried parent are traced through its recorded ancestors and exist only for the
duration of that calculation. The retained calculation index consists of
linear vectors for IDs, parent rows, prior `pedigree_F` and Mendelian-sampling
variance `D`; no relationship matrix or hidden cross-replicate cache exists.

For founders, `D = 1`. For known-parentage individual `i`,
`D[i] = 0.5 - 0.25 * (F[mother] + F[father])`. The cross-product of the two
parental contribution vectors with `D`, divided by two, is the newborn
coefficient. Dense tabulation remains test-only as an independent small-
pedigree oracle.

## Creator composition

`initialize_pedigree()` computes or verifies an initial ledger.
`pedigree_newborn_fields()` is an ordinary reproduction initializer callback
and requires two known parents. `pedigree_founder_fields()` supplies explicit
founder fields for initial records or introductions.
`pedigree_parentage_fields()` supplies known-parentage introduction fields when
both ancestors already exist in the shared pre-process state.

Creators declare the returned fields exactly. Generic creation preflight still
requires `population.pedigree_status` and `population.pedigree_F` when a
downstream process consumes them. All introduced known-parentage records must
reference the pre-creation ledger; same-batch related introductions fail.

## Validation and outputs

`validate_pedigree()` verifies completeness, topology, roles, bounds and every
coefficient. Initial state construction applies the same rule whenever
pedigree is enabled. Public execution and allocation entry points also reject
raw or externally mutated inconsistent coefficients. Creator callbacks and
engine-owned replicate continuation use an internally trusted pre-state and
derive only the new coefficient; exact full-ledger verification occurs after
an actual lineage change, not once per newborn or unchanged interval.

`pedigree_ledger()` returns the tidy persistent ancestry ledger.
`summarise_pedigree()` reports record counts and mean/maximum `pedigree_F`,
optionally for living individuals. These are conditional pedigree summaries,
not marker-diversity or population-management estimands.

## Limits

No marker data, genomic IBD, mutation, recombination, founder groups,
metafounders, uncertain parentage, mate ranking, mean-kinship management,
inbreeding-depression response, database persistence or empirical calibration
is supplied. A future marker module must be separate and keyed by persistent
individual ID; marker values cannot alter `pedigree_F`.
