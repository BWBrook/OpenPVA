# Grizzly maternal care and adult harvest

This model asks how often a small grizzly population falls below three adult females in twelve years. It illustrates the individual breeding histories and age- and sex-specific harvest that motivated the original GAPPS grizzly work. Its vital rates and its assumption that all unweaned orphans die are illustrative.

With OpenPVA installed, run `Rscript --vanilla run.R` from this directory. The two scenarios assign annual autumn mortality of 0 or 0.08 to adult females and 0.05 to adult males. Each estimate uses 40 replicates and reports its Monte Carlo standard error.

Bears age in spring and undergo age-specific natural mortality. In summer, a female aged five or older can mate if all her surviving young have reached age three. She samples one mature male, and a male can sire several litters. Each female retains her mate's ID through autumn harvest. Unweaned bears whose mother has died also die. In winter, 70% of surviving mated females give birth to one to three cubs with mean litter size two. Births to a given female are at least three years apart when a cub from each litter survives to weaning. Loss of a whole litter before summer mating allows earlier reproduction.

The initial population contains six mature females, four mature males and two cubs of a known pair. The model tracks exact pedigree, including the paternity of cubs whose sire dies after mating. The final census counts dependent bears and adult females. The individual ledger exposes parentage for each replicate.

```r
source(system.file("examples", "grizzly", "model.R", package = "OpenPVA"))
x <- OpenPVA::run_scenario(grizzly_scenario(n_runs = 1L), keep = c("census", "ledger"))
head(x$ledgers[[1L]][c("id", "mother_id", "father_id", "entry_time", "pedigree_F")])
```
