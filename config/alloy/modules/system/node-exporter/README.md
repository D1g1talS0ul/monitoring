# Node Exporter Module

Handles scraping Node Exporter metrics.

## Components

-   [`kubernetes`](#kubernetes)
-   [`local`](#local)
-   [`scrape`](#scrape)

### `kubernetes`

Handles discovery of kubernetes targets and exports them, this component does not perform any scraping at all and is not required to be used for kubernetes, as a custom service discovery and targets can be defined and passed to `node_exporter.scrape`

#### Arguments

| Name              | Required | Default                                               | Description                                                                                                                               |
| :---------------- | :------- | :---------------------------------------------------- | :---------------------------------------------------------------------------------------------------------------------------------------- |
| `namespaces`      | _no_     | `[]`                                                  | The namespaces to look for targets in, the default (`[]`) is all namespaces                                                               |
| `field_selectors` | _no_     | `[]`                                                  | The [field selectors](https://kubernetes.io/docs/concepts/overview/working-with-objects/field-selectors/) to use to find matching targets |
| `label_selectors` | _no_     | `["app.kubernetes.io/name=prometheus-node-exporter"]` | The [label selectors](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/) to use to find matching targets          |
| `port_name`       | _no_     | `metrics`                                             | The of the port to scrape metrics from                                                                                                    |

#### Exports

| Name     | Type                | Description                |
| :------- | :------------------ | :------------------------- |
| `output` | `list(map(string))` | List of discovered targets |

#### Labels

The following labels are automatically added to exported targets.

| Label       | Description                                                                                                                                         |
| :---------- | :-------------------------------------------------------------------------------------------------------------------------------------------------- |
| `app`       | Derived from the pod label value of `app.kubernetes.io/name`, `k8s-app`, or `app`                                                                   |
| `component` | Derived from the pod label value of `app.kubernetes.io/component`, `k8s-component`, or `component                                                   |
| `container` | The name of the container, usually `haproxy`                                                                                                        |
| `namespace` | The namespace the target was found in.                                                                                                              |
| `pod`       | The full name of the pod                                                                                                                            |
| `source`    | Constant value of `kubernetes`, denoting where the results came from, this can be useful for LBAC                                                   |
| `workload`  | Kubernetes workload, a combination of `__meta_kubernetes_pod_controller_kind` and `__meta_kubernetes_pod_controller_name`, i.e. `ReplicaSet/my-app` |

---

### `local`

#### Arguments

| Name   | Optional | Default | Description                            |
| :----- | :------- | :------ | :------------------------------------- |
| `port` | `true`   | `9100`  | The of the port to scrape metrics from |

#### Exports

| Name     | Type                | Description                |
| :------- | :------------------ | :------------------------- |
| `output` | `list(map(string))` | List of discovered targets |

#### Labels

The following labels are automatically added to exported targets.

| Label    | Description                                                                                  |
| :------- | :------------------------------------------------------------------------------------------- |
| `source` | Constant value of `local`, denoting where the results came from, this can be useful for LBAC |

---

### `scrape`

#### Arguments

| Name                | Required | Default                        | Description                                                                                                                                         |
| :------------------ | :------- | :----------------------------- | :-------------------------------------------------------------------------------------------------------------------------------------------------- |
| `targets`           | _yes_    | `list(map(string))`            | List of targets to scrape                                                                                                                           |
| `forward_to`        | _yes_    | `list(MetricsReceiver)`        | Must be a where scraped should be forwarded to                                                                                                      |
| `job_label`         | _no_     | `integrations/node_exporter`   | The job label to add for all mimir metric                                                                                                           |
| `keep_metrics`      | _no_     | [see code](metrics.alloy#L256) | A regular expression of metrics to keep                                                                                                             |
| `drop_metrics`      | _no_     | [see code](metrics.alloy#L249) | A regular expression of metrics to drop                                                                                                             |
| `scheme`            | _no_     | `http`                         | The scheme to use when scraping metrics                                                                                                             |
| `bearer_token_file` | _no_     | none                           | The bearer token file                                                                                                                               |
| `scrape_interval`   | _no_     | `60s`                          | How often to scrape metrics from the targets                                                                                                        |
| `scrape_timeout`    | _no_     | `10s`                          | How long before a scrape times out                                                                                                                  |
| `max_cache_size`    | _no_     | `100000`                       | The maximum number of elements to hold in the relabeling cache.  This should be at least 2x-5x your largest scrape target or samples appended rate. |
| `clustering`        | _no_     | `false`                        | Whether or not [clustering](https://node_exporter.com/docs/agent/latest/flow/concepts/clustering/) should be enabled                                |

#### Labels

The following labels are automatically added to exported targets.

| Label | Description                                    |
| :---- | :--------------------------------------------- |
| `job` | Set to the value of `argument.job_label.value` |

---

## Usage

### `kubernetes`

The following example will scrape all node_exporter instances in cluster.

```alloy
import.git "node_exporter" {
  repository = "https://github.com/node_exporter/agent-modules.git"
  revision = "main"
  path = "modules/system/node-exporter/metrics.alloy"
  pull_frequency = "15m"
}

// get the targets
node_exporter.kubernetes "targets" {}

// scrape the targets
node_exporter.scrape "metrics" {
  targets = node_exporter.kubernetes.targets.output
  forward_to = [
    prometheus.remote_write.default.receiver,
  ]
}

// write the metrics
prometheus.remote_write "local" {
  endpoint {
    url = "http://mimir:9009/api/v1/push"

    basic_auth {
      username = "example-user"
      password = "example-password"
    }
  }
}
```

### `local`

The following example will scrape node_exporter for metrics on the local machine.

```alloy
import.git "node_exporter" {
  repository = "https://github.com/node_exporter/agent-modules.git"
  revision = "main"
  path = "modules/system/node-exporter/metrics.alloy"
  pull_frequency = "15m"
}

// get the targets
node_exporter.local "targets" {}

// scrape the targets
node_exporter.scrape "metrics" {
  targets = node_exporter.local.targets.output
  forward_to = [
    prometheus.remote_write.default.receiver,
  ]
}

// write the metrics
prometheus.remote_write "default" {
  endpoint {
    url = "http://mimir:9009/api/v1/push"

    basic_auth {
      username = "example-user"
      password = "example-password"
    }
  }
}
```
