# Copyright (c) 2023 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

resource "oci_logging_log_group" "these" {
  for_each = var.logging_configuration.log_group

    compartment_id = each.value.compartment_id != null ? (length(regexall("^ocid1.*$", each.value.compartment_id)) > 0 ? each.value.compartment_id : var.compartments_dependency[each.value.compartment_id].id)  : (length(regexall("^ocid1.*$", var.logging_configuration.default_compartment_id)) > 0 ? var.logging_configuration.default_compartment_id : var.compartments_dependency[var.logging_configuration.default_compartment_id].id)
    display_name   = each.value.name
    description    = each.value.description != null ? each.value.description : each.value.name
    defined_tags   = each.value.defined_tags != null ? each.value.defined_tags : var.logging_configuration.default_defined_tags
    freeform_tags = merge(local.cislz_module_tag, each.value.freeform_tags != null ? each.value.freeform_tags : var.logging_configuration.default_freeform_tags)
}

resource "oci_logging_log" "these" {
  for_each = var.logging_configuration.service_logs != null ? var.logging_configuration.service_logs : {}
    display_name = each.value.name
    log_group_id = each.value.log_group_id
    log_type     = "SERVICE"
    configuration {
      compartment_id = each.value.compartment_id
      source {
        category    = each.value.category
        resource    = each.value.resource_id
        service     = each.value.service
        source_type = "OCISERVICE"
      }
    }
    is_enabled         = each.value.is_enabled
    retention_duration = each.value.retention_duration
    defined_tags       = each.value.defined_tags != null ? each.value.defined_tags : var.logging_configuration.default_defined_tags
    freeform_tags = merge(local.cislz_module_tag, each.value.freeform_tags != null ? each.value.freeform_tags : var.logging_configuration.default_freeform_tags)
}

resource "oci_logging_log" "these_custom" {
  for_each = var.logging_configuration.custom_logs != null ? var.logging_configuration.custom_logs : {}
    display_name = each.value.name
    log_group_id = oci_logging_log_group.these[each.value.log_group_id].id
    log_type     = "CUSTOM"
    is_enabled         = each.value.is_enabled
    retention_duration = each.value.retention_duration
    defined_tags  = each.value.defined_tags != null ? each.value.defined_tags : var.logging_configuration.default_defined_tags
    freeform_tags = merge(local.cislz_module_tag, each.value.freeform_tags != null ? each.value.freeform_tags : var.logging_configuration.default_freeform_tags)
}

resource "oci_logging_unified_agent_configuration" "these" {
  for_each = var.logging_configuration.custom_logs != null ? var.logging_configuration.custom_logs : {}
    compartment_id = each.value.compartment_id != null ? each.value.compartment_id : var.logging_configuration.default_compartment_id
    is_enabled     = each.value.is_enabled
    description    = format("%s%s", "Agent configuration for ", each.value.name)
    display_name   = format("%s%s", "Agent_", each.value.name)
    service_configuration {
      configuration_type = "LOGGING"
      destination {
        log_object_id = oci_logging_log.these_custom[each.key].id
      }
      sources {
        source_type = "LOG_TAIL"
        paths       = each.value.path
        dynamic "parser" {
          for_each = each.value.parser == "NONE" ? [1] : []
          content {
            parser_type = "NONE"
          }
        }
        dynamic "parser" {
          for_each = each.value.parser == "SYSLOG" ? [1] : []
          content {
            parser_type        = "SYSLOG"
            rfc5424time_format = ""
            syslog_parser_type = ""
          }
        }
        dynamic "parser" {
          for_each = each.value.parser == "CSV" || each.value.parser == "TSV" ? [1] : []
          content {
            parser_type = lookup(each.value, "parser", "CSV")
            keys        = []
            delimiter   = ","
          }
        }
        dynamic "parser" {
          for_each = each.value.parser == "REGEXP" ? [1] : []
          content {
            parser_type = "REGEXP"
            expression  = ".*"
            time_format = ""
          }
        }
        dynamic "parser" {
          for_each = each.value.parser == "MULTILINE" ? [1] : []
          content {
            parser_type      = "MULTILINE"
            format           = ""
            format_firstline = ""
          }
        }
        dynamic "parser" {
          for_each = each.value.parser == "APACHE_ERROR" ? [1] : []
          content {
            parser_type = "APACHE_ERROR"
          }
        }
        dynamic "parser" {
          for_each = each.value.parser == "APACHE2" ? [1] : []
          content {
            parser_type = "APACHE2"
          }
        }
        dynamic "parser" {
          for_each = each.value.parser == "AUDITD" ? [1] : []
          content {
            parser_type = "AUDITD"
           }
        }
        dynamic "parser" {
          for_each = each.value.parser == "JSON" ? [1] : []
          content {
            parser_type = "JSON"
            time_type   = "UNIXTIME"
          }
        }
        dynamic "parser" {
          for_each = each.value.parser == "CRI" ? [1] : []
          content {
            parser_type = "CRI"
            nested_parser {
              time_format      = "%Y-%m-%dT%H:%M:%S.%L%z"
              field_time_key   = "time"
              is_keep_time_key = false
            }
          }
        }
        name = each.key
      }
    }

    defined_tags  = each.value.defined_tags != null ? each.value.defined_tags : var.logging_configuration.default_defined_tags
    freeform_tags = merge(local.cislz_module_tag, each.value.freeform_tags != null ? each.value.freeform_tags : var.logging_configuration.default_freeform_tags)

    group_association {
      group_list = each.value.dynamic_groups
    }
}
