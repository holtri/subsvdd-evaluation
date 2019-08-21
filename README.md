# SubSVDD Evaluation

This repository contains scripts and notebooks to reproduce the experiments and analyses of the paper

> Holger Trittenbach and Klemens Böhm. 2019. One-Class Active Learning for Outlier Detection with Multiple Subspaces. In The 28th ACM International Conference on Information and Knowledge Management (CIKM ’19), November 3--7, 2019, Beijing, China. ACM, New York, NY, USA, 10 pages. https://doi.org/10.1145/3357384.3357873

For more information about this research project, see also the [SubSVDD project website](https://www.ipd.kit.edu/mitarbeiter/subsvdd/).
For a general overview and a benchmark on one-class active learning see the [OCAL project website](https://www.ipd.kit.edu/ocal/).

## Quick Start

The analysis and main results of the experiments can be found under [notebooks](https://github.com/holtri/subsvdd-evaluation/tree/master/notebooks):
  * `illustration_outlier-asymmetry.ipynb`: Figure 1 and Figure 2
  * `illustration_page-data-example.ipynb`: Figure 3b
  * `R-experiment-evaluation`
    * `evaluation-part1.ipynb`: Table 1 and Figure 5
    * `evaluation-part2.ipynb`: Figure 6
    * `subspace_heatmap.ipynb`: Figure 3a

To execute the notebooks, make sure you follow the [setup section](#setup), and [download the raw results](https://www.ipd.kit.edu/mitarbeiter/subsvdd/output.zip) into `data/output/`.

## Prerequisites

The experiments are implemented in [Julia](https://julialang.org/), some of the evaluation notebooks are written in R.
This repository contains code to setup the experiments, to execute them, and to analyze the results.
The one-class classifiers (SubSVDD and the competitors SSAD and SVDDneg) and active learning methods are implemented in two separate Julia packages: [SVDD.jl](https://github.com/englhardt/SVDD.jl) and [OneClassActiveLearning.jl](https://github.com/englhardt/OneClassActiveLearning.jl).

### Setup

Just clone the repo.
```bash
$ git clone https://github.com/holtri/subsvdd-evaluation.git
```
* Experiments require Julia 1.1, requirements are defined in `Manifest.toml`. To instantiate, start julia in the `subsvdd-evaluation` directory with `julia --project=. ` and run `julia> ]instantiate`. See [Julia documentation](https://docs.julialang.org/en/v1.0/stdlib/Pkg/#Using-someone-else's-project-1) for general information on how to setup this project.
* Notebooks require
  * Julia 1.1
  * R 3.6: `tidyverse`, `assertthat`, `xtables`

### Repo Overview

* `data`
  * `input`
    * `raw`: unprocessed data files
    * `processed`: output directory of _preprocess_data.jl_
  * `output`: output directory of experiments; _generate_experiments.jl_ creates the folder structure and experiments; _run_experiments.jl_ writes results and log files
* `notebooks`: jupyter notebooks to analyze experimental results
  * `illustration_outlier-asymmetry.ipynb`: Figure 1 and Figure 2
  * `illustration_page-data-example.ipynb`: Figure 3b
  * `R-experiment-evaluation`
    * `evaluation-part1.ipynb`: Table 1 and Figure 5
    * `evaluation-part2.ipynb`: Figure 6
    * `subspace_heatmap.ipynb`: Figure 3a
* `scripts`
  * `config`: configuration files for experiments
    * `config.jl`: high-level configuration
    * `baslines.jl`, `largesubspaces.jl`, `smallsubspaces-wanglimit.jl`: experiment configs
    * `v-comparison.jl`: experiment config for parameter comparison
  * `check_pkg.jl`: check package versions (for distributed execution)
  * `preprocess_data.jl`: preprocess data files into common format
  * `generate_experiments.jl`: generates experiments
  * `reduce_results.jl`: reduces result json files to single result csv
  * `run_experiments`: executes experiments

## Overview

Each step of the experiments can be reproduced, from the raw data files to the final plots that are presented in the paper.
The experiment is a pipeline of several dependent processing steps.
Each of the steps can be executed standalone, and takes a well-defined input, and produces a specified output.
The Section [Experiment Pipeline](#experiment-pipeline) describes each of the process steps.

Running the benchmark is compute intensive and takes many CPU hours.
Therefore, we also provide the [results to download](https://www.ipd.kit.edu/mitarbeiter/subsvdd/output.zip) (51 MB).
This allows to analyze the results in the notebooks without having to run the whole pipeline.

The code is licensed under a [MIT License](https://github.com/kit-dbis/ocal-evaluation/blob/master/LICENSE.md) and the result data under a [Creative Commons Attribution 4.0 International License](https://creativecommons.org/licenses/by/4.0/).
If you use this code or data set in your scientific work, please reference the companion paper.

## Experiment Pipeline

The benchmark pipeline uses config files to set paths and experiment parameters.
There are two types of config files:
* `scripts/config.jl`: this config defines high-level information on the experiment, such as where the data files are located, and log levels.
* `scripts/<baslines|largesubspaces|smallsubspaces-wanglimit|v-comparison>.jl`: These config files define the experimental grid, including the data sets, classifiers, and active-learning strategies.

1. _Data Preprocessing_: The preprocessing step transforms publicly available benchmark data sets into a common csv format, and subsamples large data sets to 1000 observations.
   * **Input:** Download [semantic.tar.gz](http://www.dbs.ifi.lmu.de/research/outlier-evaluation/input/semantic.tar.gz) and [literature.tar.gz](http://www.dbs.ifi.lmu.de/research/outlier-evaluation/input/literature.tar.gz) containing the .arff files from the DAMI benchmark repository and extract into `data/input/raw/<data set>` (e.g. `data/input/raw/Annthyroid/`).
   * **Execution:**
   ```bash
      $ julia --project="." preprocess_data.jl <config.jl>
   ```
   * **Output:** .csv files in `data/input/processed/noise`

   We also provide our [preprocessed data to download](https://www.ipd.kit.edu/mitarbeiter/subsvdd/input.zip) (3 MB).

2. _Generate Experiments_: This step creates a set of experiments. Each experiment in this set is a specific combination of
    * `data set path` (e.g., "data/input/Annthyroid/Annthyroid_withoutdupl_norm_05_v01_r01.csv")
    * `initial pool strategy` (e.g., "Pu")
    * `split strategy` (e.g., "Sf")
    * `model` (e.g., SubSVDD)
    * `init strategy` (e.g., SimpleCombinedStrategy)
    * `query strategy` (e.g., DecisionBoundaryPQs)
    * `parameters` (e.g., number of active learning iterations)

   These specific combinations are created as a cross product of the vectors in the config file that is passed as an argument.
   * **Input**: Full path to config file `<config_file.jl>` (e.g., config/config_evaluation_part1.jl), preprocessed data files
   * **Execution:**
   ```bash
    $ julia --project="." generate_experiments.jl <config_file.jl>
   ```
   * **Output:**
     * Creates an experiment directory with the naming `<exp_name>`. The directories created contains several items:
       * `log` directory: skeleton for experiment logs (one file per experiment), and worker logs (one file per worker)
       * `results` directory: skeleton for result files
       * `experiments.jser`: this contains a serialized Julia Array with experiments. Each experiment is a Dict that contains the specific combination. Each experiment can be identified by a unique hash value.
       * `experiment_hashes`: file that contains the hash values of the experiments stored in `experiments.jser`
       * `generate_experiments.jl`: a copy of the file that generated the experiments
       * `config.jl`: a copy of the config file used to generate the experiments

3. _Run Experiments_: This step executes the experiments created in Step 2.
Each experiment is executed on a worker. In the default configuration, a worker is one process on the localhost.
For distributed workers, see Section [Infrastructure and Parallelization](#infractructure-and-parallelization).
A worker takes one specific configuration, runs the active learning experiment, and writes result and log files.
  * **Input:** Generated experiments from step 2.
  * **Execution:**
  ```bash
     $ julia --project="." run_experiments.jl /full/path/to/ocal-evaluation/scripts/config.jl
  ```
  * **Output:** The output files are named by the experiment hash
    * Experiment log (e.g., `data/output/evaluation_part1/02-subsvdd-largesubspaces/results/10121309769577703138.log`)
    * Result .json file (e.g., `data/output/evaluation_part1/02-subsvdd-largesubspaces/results/Annthyroid/Annthyroid_withoutdupl_norm_05_v01_nnoise-mu=0.0_s=0.01__SubspaceQs{DecisionBoundaryPQs}_SubSVDD_10121309769577703138.json`)

4. _Reduce Results_: Merge of an experiment directory into one .csv by using summary statistics
    * **Input:** Full path to finished experiments.
    * **Execution:**
    ```bash
       $ julia --project="." reduce_results.jl </full/path/to/data/output>
    ```
    * **Output:** A result csv file, `data/output/evaluation-part1.csv`.

5. _Analyze Results:_ jupyter notebooks in the `notebooks`directory to analyze the reduced `.csv`, and individual `.json` files

## Infrastructure and Parallelization

Step 3 _Run Experiments_ can be parallelized over several workers. In general, one can use any [ClusterManager](https://github.com/JuliaParallel/ClusterManagers.jl). In this case, the node that executes `run_experiments.jl` is the driver node. The driver node loads the `experiments.jser`, and initiates a function call for each experiment on one of the workers via `pmap`.

## Authors
We welcome contributions and bug reports.

This package is developed and maintained by [Holger Trittenbach](https://github.com/holtri/)
