# seeded replicate output snapshots remain stable

    {
      "type": "list",
      "attributes": {
        "names": {
          "type": "character",
          "attributes": {},
          "value": ["summary_slice", "extinction"]
        }
      },
      "value": [
        {
          "type": "list",
          "attributes": {
            "names": {
              "type": "character",
              "attributes": {},
              "value": ["run", "year", "n_alive", "n_births", "env_surv_mult", "cat_surv_mult", "catastrophe"]
            },
            "row.names": {
              "type": "integer",
              "attributes": {},
              "value": [1, 2, 3, 4, 5, 6, 7, 8]
            },
            "class": {
              "type": "character",
              "attributes": {},
              "value": ["tbl_df", "tbl", "data.frame"]
            }
          },
          "value": [
            {
              "type": "integer",
              "attributes": {},
              "value": [1, 1, 1, 1, 2, 2, 2, 2]
            },
            {
              "type": "integer",
              "attributes": {},
              "value": [1, 2, 3, 4, 1, 2, 3, 4]
            },
            {
              "type": "integer",
              "attributes": {},
              "value": [24, 27, 21, 6, 28, 29, 19, 24]
            },
            {
              "type": "integer",
              "attributes": {},
              "value": [5, 7, 5, 0, 10, 5, 1, 7]
            },
            {
              "type": "double",
              "attributes": {},
              "value": [0.878742, 0.959883, 0.746595, 1.085029, 0.984226, 0.950278, 0.829261, 1.038196]
            },
            {
              "type": "double",
              "attributes": {},
              "value": [1, 1, 1, 0.5, 1, 1, 1, 1]
            },
            {
              "type": "logical",
              "attributes": {},
              "value": [false, false, false, true, false, false, false, false]
            }
          ]
        },
        {
          "type": "list",
          "attributes": {
            "class": {
              "type": "character",
              "attributes": {},
              "value": ["tbl_df", "tbl", "data.frame"]
            },
            "row.names": {
              "type": "integer",
              "attributes": {},
              "value": [1, 2, 3]
            },
            "names": {
              "type": "character",
              "attributes": {},
              "value": ["run", "went_extinct", "time_to_extinction"]
            }
          },
          "value": [
            {
              "type": "integer",
              "attributes": {},
              "value": [1, 2, 3]
            },
            {
              "type": "logical",
              "attributes": {},
              "value": [false, false, false]
            },
            {
              "type": "integer",
              "attributes": {},
              "value": ["NA", "NA", "NA"]
            }
          ]
        }
      ]
    }

# schema migration snapshot remains stable

    {
      "type": "list",
      "attributes": {
        "names": {
          "type": "character",
          "attributes": {},
          "value": ["schema_version", "breeding_prob_table", "fecundity_lambda_table", "reproduction_ev"]
        }
      },
      "value": [
        {
          "type": "integer",
          "attributes": {},
          "value": [2]
        },
        {
          "type": "list",
          "attributes": {
            "names": {
              "type": "character",
              "attributes": {},
              "value": ["age_min", "age_max", "sex", "p_breed"]
            },
            "row.names": {
              "type": "integer",
              "attributes": {},
              "value": [1, 2]
            },
            "class": {
              "type": "character",
              "attributes": {},
              "value": ["tbl_df", "tbl", "data.frame"]
            }
          },
          "value": [
            {
              "type": "double",
              "attributes": {},
              "value": [4, 0]
            },
            {
              "type": "double",
              "attributes": {},
              "value": [100, 100]
            },
            {
              "type": "character",
              "attributes": {},
              "value": ["F", "M"]
            },
            {
              "type": "double",
              "attributes": {},
              "value": [1, 0]
            }
          ]
        },
        {
          "type": "list",
          "attributes": {
            "names": {
              "type": "character",
              "attributes": {},
              "value": ["age_min", "age_max", "sex", "lambda"]
            },
            "row.names": {
              "type": "integer",
              "attributes": {},
              "value": [1, 2]
            },
            "class": {
              "type": "character",
              "attributes": {},
              "value": ["tbl_df", "tbl", "data.frame"]
            }
          },
          "value": [
            {
              "type": "double",
              "attributes": {},
              "value": [4, 0]
            },
            {
              "type": "double",
              "attributes": {},
              "value": [100, 100]
            },
            {
              "type": "character",
              "attributes": {},
              "value": ["F", "M"]
            },
            {
              "type": "double",
              "attributes": {},
              "value": [1.4, 0]
            }
          ]
        },
        {
          "type": "list",
          "attributes": {
            "names": {
              "type": "character",
              "attributes": {},
              "value": ["env_repro_p_sd", "env_repro_lambda_sd", "cat_repro_prob", "cat_repro_mult"]
            }
          },
          "value": [
            {
              "type": "double",
              "attributes": {},
              "value": [0.1]
            },
            {
              "type": "double",
              "attributes": {},
              "value": [0.2]
            },
            {
              "type": "double",
              "attributes": {},
              "value": [0.25]
            },
            {
              "type": "double",
              "attributes": {},
              "value": [0.6]
            }
          ]
        }
      ]
    }

# seeded spatial-genetic output snapshots remain stable

    {
      "type": "list",
      "attributes": {
        "names": {
          "type": "character",
          "attributes": {},
          "value": ["occupancy_overall", "transitions_overall"]
        }
      },
      "value": [
        {
          "type": "list",
          "attributes": {
            "names": {
              "type": "character",
              "attributes": {},
              "value": ["year", "patch_id", "n_runs", "mean_n_alive", "p_occupied", "n_extinct", "alive_only"]
            },
            "row.names": {
              "type": "integer",
              "attributes": {},
              "value": [1, 2, 3, 4, 5, 6]
            },
            "class": {
              "type": "character",
              "attributes": {},
              "value": ["tbl_df", "tbl", "data.frame"]
            }
          },
          "value": [
            {
              "type": "integer",
              "attributes": {},
              "value": [1, 1, 2, 2, 3, 3]
            },
            {
              "type": "integer",
              "attributes": {},
              "value": [1, 2, 1, 2, 1, 2]
            },
            {
              "type": "integer",
              "attributes": {},
              "value": [3, 3, 3, 3, 3, 3]
            },
            {
              "type": "double",
              "attributes": {},
              "value": [8, 8, 8, 8, 8.666667, 7.333333]
            },
            {
              "type": "double",
              "attributes": {},
              "value": [1, 1, 1, 1, 1, 1]
            },
            {
              "type": "integer",
              "attributes": {},
              "value": [0, 0, 0, 0, 0, 0]
            },
            {
              "type": "logical",
              "attributes": {},
              "value": [true, true, true, true, true, true]
            }
          ]
        },
        {
          "type": "list",
          "attributes": {
            "names": {
              "type": "character",
              "attributes": {},
              "value": ["origin_patch", "destination_patch", "mean_n_individuals", "total_n_individuals", "p_transition_given_origin", "alive_only"]
            },
            "row.names": {
              "type": "integer",
              "attributes": {},
              "value": [1, 2, 3, 4]
            },
            "class": {
              "type": "character",
              "attributes": {},
              "value": ["tbl_df", "tbl", "data.frame"]
            }
          },
          "value": [
            {
              "type": "integer",
              "attributes": {},
              "value": [1, 1, 2, 2]
            },
            {
              "type": "integer",
              "attributes": {},
              "value": [1, 2, 1, 2]
            },
            {
              "type": "double",
              "attributes": {},
              "value": [6.777778, 1.444444, 1.777778, 6]
            },
            {
              "type": "integer",
              "attributes": {},
              "value": [61, 13, 16, 54]
            },
            {
              "type": "double",
              "attributes": {},
              "value": [0.824324, 0.175676, 0.228571, 0.771429]
            },
            {
              "type": "logical",
              "attributes": {},
              "value": [true, true, true, true]
            }
          ]
        }
      ]
    }

