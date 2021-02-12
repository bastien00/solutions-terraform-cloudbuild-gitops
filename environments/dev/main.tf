# Copyright 2019 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


locals {
  env = "dev"
}

provider "google" {
  version = "3.51.1"
  project = "${var.project}"
  region  = "us-central1"
  zone    = "us-central1-c"
}



resource "google_project_service" "service" {

  for_each = toset([
    "compute.googleapis.com",
    "oslogin.googleapis.com",
  ])

  service = each.key
  project            = "orange-hubdata-cbs-dev"
  disable_on_destroy = false
}
resource "google_bigquery_dataset" "dataset" {
  dataset_id                  = "example_dataset"
  friendly_name               = "test"
  description                 = "This is a test description"
  location                    = "europe-west3"
  default_table_expiration_ms = 3600000

  labels = {
    env = "default"
  }
#to be checked
# access {
#    role          = "OWNER"
#  user_by_email = google_service_account.bqowner.email
#  }

#  access {
#    role   = "WRITER"
#    user_by_email = google_service_account.bqowner.email
#  }

#  access {
#    role   = "READER"
#    group_by_email = "poc-hd-cbs-fibre@orange.com"

#  }

}

resource "google_service_account" "bqowner" {
  account_id = "bqowner"
}


resource "google_bigquery_table" "rtable_fibre" {
  dataset_id = google_bigquery_dataset.dataset.dataset_id
  table_id   = "table_fibre"
}

resource "google_bigquery_job" "job" {
  job_id     = "job_query"

  labels = {
    "example-label" ="label_value_fibre"
  }

  query {
    query = "SELECT SUM(nb_logements) AS total_logement, SUM(nb_logements_professionnel) AS total_logement_pro, count(cle_site_id) AS num_site, date_etat_production FROM orange-hubdata-bdf-dev.orange_bdf_hda_socle_optimumorange_poc.bq_fai_optimumorange_oi GROUP BY date_etat_production"


    destination_table {
      project_id = google_bigquery_table.rtable_fibre.project
      dataset_id = google_bigquery_table.rtable_fibre.dataset_id
      table_id   = google_bigquery_table.rtable_fibre.table_id
    }

    allow_large_results = true
    flatten_results = true

    script_options {
      key_result_statement = "LAST"
    }
  }
  location="europe-west3"
}

# Bucket to store Airflow DAG
resource "google_storage_bucket" "rcomposer_bucket" {
  name          = "composer_bucket"
  location      = "europe-west3"
  force_destroy = true

  uniform_bucket_level_access = true

}


# Composer 


resource "google_composer_environment" "rcomposer" {
  name   = "composer_name"
  region = "us-central1"


  config {
    software_config {
      airflow_config_overrides = {
        core-load_example = "True"
      }

      pypi_packages = {
        numpy = ""
        scipy = "==1.1.0"
      }

      env_variables = {
        FOO = "bar"
      }
    }
  }
}








