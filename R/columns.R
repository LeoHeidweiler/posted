# Import necessary libraries
library(dplyr)
library(assertthat)
library(GROAN)

#' @title is_float
#'
#' @description Checks if a given string can be converted to a floating-point number in Python.
#'
#' @param string Character. String to check.
#'
#' @return Logical. \code{TRUE} if conversion was successful, \code{FALSE} if not.
#'
#' @examples
#' # Example usage:
#' is_numeric("3.14")
#'
#' @export
is_float <- function(string) {
  if (length(as.numeric(string)) == 1 && !is.na(as.numeric(string))) {
    return(TRUE)
  } else {
    return(FALSE)
  }
}


#' @title AbstractColumnDefinition
#'
#' @description Abstract class to store columns
AbstractColumnDefinition <- R6::R6Class("AbstractColumnDefinition",
    private = list(
        ..col_type = NULL,
        ..name = NULL,
        ..description = NULL,
        ..dtype = NULL,
        ..required = NULL
    ),




  public = list(
    #' @description Creates a new instance of the AbstractColumnDefinition class
    #'
    #' @param col_type (`data.frame`)\cr
    #'  Type of the column.
    #' @param name (`character(1)`)\cr
    #'  Name of the column.
    #' @param description (`character(1)`)\cr
    #'  Description of the column.
    #' @param dtype (`Data type`)\cr
    #'  Data type of the column.
    #' @param required (`Logical`)\cr
    #'  Bool that specifies if the column is required.
    initialize = function(col_type, name, description, dtype, required) {

        if (!(col_type %in% list('field', 'variable', 'unit', 'value', 'comment'))) {
            stop(sprintf("Columns must be of type field, variable, unit, value, or comment but found: %s", col_type))
        }
        if (!is.string(name)) {
            stop(sprintf("The 'name' must be a string but found type %s: %s", typeof(name), name))
        }
        if (!is.string(description)) {
            stop(sprintf("The 'description' must be a string but found type %s: %s", typeof(description), description))
        }
        if (!((is.string(dtype)) && (dtype %in% list('float', 'str', 'category')))) {
            stop(sprintf("The 'dtype' must be a valid data type but found %s", dtype))
        }
        if (!is.logical(required)) {
            stop(sprintf("The 'required' argument must be a bool but found: %s", required))
        }

        private$..col_type <- col_type
        private$..name <- name
        private$..description <- description
        private$..dtype <- dtype
        private$..required <- required


    },
    #' @description
    #' Tests if cell is allowed
    #'
    #' @param cell cell to test
    is_allowed = function(cell) {
      TRUE
    }

  ),
  active = list(
    #' @field col_type (`character(1)`)
    #' Type of the column, Read-only
    col_type = function() {
      private$..col_type
    },

    #' @field name (`character(1)`)\cr
    #' Name of the column, Read-only
    name = function() {
      private$..name
    },

    #' @field description (`character(1)`)
    #' Description of the column, Read-only
    description = function() {
      private$..description
    },

    #' @field dtype (`character(1)`)
    #' Data type of the column, Read-only
    dtype = function() {
      private$..dtype
    },

    #' @field required (`logical`)
    #' If the column is required, Read-only
    required = function() {
      private$..required
    },

    #' @field default (`character(1)`)
    #' The default of the column, Read-only
    default = function() {
      NA
    }


  )
)


#' @title VariableDefinition
#'
#' @description Class to store variable columns
VariableDefinition <- R6::R6Class("VariableDefinition", inherit = AbstractColumnDefinition,

  public = list(
    #' @description Creates a new instance of the VariableDefinition class
    #'
    #' @param name (`Character`):
    #'  Name of the column.
    #' @param description (`Character`):
    #'  Description of the column.
    #' @param required (`Logical`):
    #'  Bool that specifies if the column is required.
    initialize = function(name, description, required) {
      super$initialize(col_type = 'variable',
                       name = name,
                       description = description,
                       dtype = 'category',
                       required = required)
    },

    #' @description
    #' Tests if cell is allowed
    #'
    #' @param cell cell to test
    is_allowed = function(cell) {
      if (is.na(cell)) {
        return(!private$..required)
      }
      return(is.character(cell) && (cell %in% variables))
    }
  )
)


#' @title UnitDefinition
#'
#' @description Class to store Unit columns
UnitDefinition <- R6::R6Class("UnitDefinition", inherit = AbstractColumnDefinition,

  public = list(
    #' @description Creates a new instance of the UnitDefinition class
    #'
    #' @param name Character. Name of the column.
    #' @param description Character. Description of the column.
    #' @param required Logical. Bool that specifies if the column is required.
    initialize = function(name, description, required) {
      super$initialize(col_type = 'unit',
                       name = name,
                       description = description,
                       dtype = 'category',
                       required = required)
    },

    #' @description
    #' Tests if cell is allowed
    #'
    #' @param cell cell to test
    is_allowed = function(cell) {
      if (is.na(cell)) {
        return(!private$required)
      }
      if (!is.character(cell)) {
        return(FALSE)
      }
      tokens <- strsplit(cell, ';')[[1]]
      if (length(tokens) == 1) {
        return (tokens[1] %in% ureg)
      } else if (length(tokens) == 2) {
        return (tokens[1] %in% ureg && tokens[2] %in% unit_variants)
      } else {
        return(FALSE)
      }
    }
  )
)
#' @title ValueDefinition
#'
#' @description Class to store Value columns
ValueDefinition <- R6::R6Class("ValueDefinition", inherit = AbstractColumnDefinition,

  public = list(
    #' @description Creates a new instance of the ValueDefinition class
    #'
    #' @param name Character. Name of the column.
    #' @param description Character. Description of the column.
    #' @param required Logical. Bool that specifies if the column is required.
    initialize = function(name, description, required) {
      super$initialize(col_type = 'value',
                       name = name,
                       description = description,
                       dtype = 'float',
                       required = required)
    },

    #' @description  Tests if cell is allowed
    #'
    #' @param cell cell to test
    is_allowed = function(cell) {
      if (is.na(cell)) {
        return(!private$required)
      }
      return(is.numeric(cell))
    }
  )
)

#' @title CommentDefinition
#'
#' @description Class to store comment columns
CommentDefinition <- R6::R6Class("CommentDefinition", inherit = AbstractColumnDefinition,
  public = list(
    #' @description Creates a new instance of the CommentDefinition Class
    #
    #' @param name Character. Name of the column.
    #' @param description Character. Description of the column.
    #' @param required Logical. Bool that specifies if the column is required.
    initialize = function(name, description, required) {
      super$initialize(col_type = 'comment',
                       name = name,
                       description = description,
                       dtype = 'str',
                       required = required)
    },

    #' @description  Tests if cell is allowed
    #'
    #' @param cell cell to test
    is_allowed = function(cell) {
      TRUE
    }
  )
)


#' @title AbstractFieldDefinition
#'
#' @description Abstract class to store fields
AbstractFieldDefinition <- R6::R6Class("AbstractFieldDefinition", inherit = AbstractColumnDefinition,
  private = list(
    ..field_type = NULL,
    ..coded = NULL,
    ..codes = NULL,

    ..expand = function(df, col_id, field_vals, ...) {
      df[df[[col_id]] == "*", col_id] = paste(field_vals, collapse=',')
      result_df <- separate_rows(df, col_id, sep=',')
      return(result_df)
    },

    ..select = function(df, col_id, field_vals, ...) {
      df[df[[col_id]] %in% field_vals, , drop = FALSE]
    }

  ),


  public = list(
    #' @description Creates a new instance of the AbstractFieldDefinition Class
    #'
    #' @param field_type Type of the field
    #' @param name Name of the field
    #' @param description Description of the field
    #' @param dtype Data type of the field
    #' @param coded If the field is coded
    #' @param codes Optional codes for the field (default: NULL)
    initialize = function(field_type, name, description, dtype, coded, codes = NULL) {
      if (!(field_type %in% list('case', 'component'))) {
        stop("Fields must be of type case or component.")
      }

     super$initialize(col_type = 'field',
                       name = name,
                       description = description,
                       dtype = dtype,
                       required = TRUE)

      private$..field_type <- field_type
      private$..coded <- coded
      private$..codes <- codes
    },



    #' @description  Tests if cell is allowed
    #'
    #' @param cell cell to test
    is_allowed = function(cell) {
      if (is.na(cell)) {
        return(FALSE)
      }
      if (private$..coded) {

        return(cell %in% names(private$..codes) || cell == '*' ||
               (cell == '#' && private$..col_type == 'component'))
      } else {
        return(TRUE)
      }
    },


    #' @description Select and expand fields which are valid for multiple periods or other field vals
    #'
    #' @param df DataFrame where fields should be selected and expanded
    #' @param col_id col_id of the column to be selected and expanded
    #' @param field_vals NULL or list of field_vals to select and expand
    #' @param ... Additional keyword arguments
    #'
    #' @return DataFrame where fields are selected and expanded
    #'
    #' @examples
    #' # Example usage:
    #' # select_and_expand(df, "col_id", field_vals = NULL)
    #'
    #' @export
    select_and_expand = function(df, col_id, field_vals = NA, ...) {

      if (is.null(field_vals)) {
        if (col_id == 'period') {
          field_vals <- default_periods
        } else if (private$..coded) {
          field_vals <- names(private$..codes)
        } else {
          field_vals <- unique(df[[col_id]])
          field_vals <- field_vals[!is.na(field_vals) & field_vals != '*']
        }
      } else {
        # ensure that field values is a list of element (not tuple, not single value)
        if(!(is.list(field_vals))) {
        field_vals <- as.list(field_vals)}
        for (val in field_vals) {
          if (!self$is_allowed(val)) {
            # check that every element is of allowed type
            stop(paste("Invalid type selected for field " ,col_id, ": ", val, sep = ""))
          }
        }
        if ("*" %in% field_vals) {
          stop(paste("Selected values for field ", col_id, " must not contain the asterisk.",
                    "Omit the ", col_id, " argument to select all entries.", sep = ""))
        }
      }
      # expand
      df <- private$..expand(df, col_id, field_vals, ...)
      # select
      df <- private$..select(df, col_id, field_vals, ...)
      # return
      return(df)
    }
  ),

  active = list(
    #' @field field_type (`character(1)`):
    #' Type of the field, Read-only
    field_type = function() {
      private$..field_type
    },

    #' @field coded (`logical`):
    #' If the field is coded, Read-only
    coded = function() {
      private$..coded
    },

    #' @field codes :
    #' Codes of the field, Read-only
    codes = function() {
      private$..codes

    },

    #' @field default (`character(1)`):
    #' Default of the field, Read-only
    default = function() {
      if (private$..field_type == 'case') {
        return('*')
      } else {
        return('#')
      }
    }
  )
)

#' @title RegionFieldDefinition
#'
#' @description Class to store Region fields
RegionFieldDefinition <- R6::R6Class("RegionFieldDefinition", inherit = AbstractFieldDefinition,
  public = list(
    #' @description Creates a new instance of the RegionFieldDefinition class
    #' @param name Character. Name of the field.
    #' @param description Character. Description of the field.
    initialize = function(name, description) {
      super$initialize(
        field_type = 'case',
        name = name,
        description = description,
        dtype = 'category',
        coded = TRUE,
        codes = list('World' = 'World')  # TODO: Insert list of country names here.
      )
    }
  )
)


#' @title PeriodFieldDefinition
#'
#' @description Class to store Period fields
PeriodFieldDefinition <- R6::R6Class("PeriodFieldDefinition", inherit = AbstractFieldDefinition,
  private = list(


    ..expand = function(df, col_id, field_vals, ...) {
      # expand period rows
      df[df[[col_id]] == "*", col_id] = paste(field_vals, collapse=',')
      result_df <- separate_rows(df, col_id, sep=',')
      # Convert 'period' column to float
      result_df[[col_id]] <- as.numeric(result_df[[col_id]])

      return(result_df)
    },

    # group by identifying columns and select periods/generate time series
    ..select = function(df, col_id, field_vals, ...) {
      kwargs <- list(...)
      # Get list of groupable columns
      group_cols <- setdiff(names(df), c(col_id, 'value'))

      # Perform group_by and do not drop NA values
      grouped <- df %>% group_split(across(all_of(group_cols)), .drop = FALSE)

      # Create return list
      ret <- list()

      # Loop over groups
      for (i in seq_along(grouped)) {
        group_df <- grouped[[i]]

        # Get rows in group
        rows <- group_df %>%
          select(all_of(col_id), "value")

        # Get a list of periods that exist
        periods_exist <- unique(rows[[col_id]])

        # Create dataframe containing rows for all requested periods
        req_rows <- data.frame()
        req_rows <-setNames(data.frame(unlist(field_vals)),col_id )
        req_rows[[paste0(col_id, "_upper")]] <- sapply(field_vals, function(p) {
            filtered_values <- periods_exist[periods_exist >= p]

            if (length(filtered_values) == 0 || all(is.na(filtered_values))) {
              return(NaN)
            } else {
              return(min(filtered_values, na.rm = TRUE))
            }
          })
        req_rows[[paste0(col_id, "_lower")]] <- sapply(field_vals, function(p) {
            filtered_values <- periods_exist[periods_exist <= p]
            if (length(filtered_values) == 0 || all(is.na(filtered_values))) {
              return(NaN)
            } else {
              return(max(filtered_values, na.rm = TRUE))
            }
          })


        # Set missing columns from group
        req_rows[group_cols] <- group_df%>% slice(1) %>% select(all_of(group_cols))

        # check case
        cond_match <- req_rows[[col_id]] %in% periods_exist
        cond_extrapolate <- is.na(req_rows[[paste0(col_id, "_upper")]]) | is.na(req_rows[[paste0(col_id, "_lower")]])

        # Match
        rows_match <- req_rows[cond_match, ] %>%
            merge(rows, by = col_id)


        # Extrapolate
        if (!("extrapolate_period" %in% names(kwargs)) || kwargs$extrapolate_period) {

          rows_extrapolate <- req_rows[!cond_match & cond_extrapolate, ] %>% mutate(period_combined = ifelse(!is.na(!!sym(paste0(col_id, "_upper"))), !!sym(paste0(col_id, "_upper")), !!sym(paste0(col_id, "_lower"))))
          rows_ext <- rows %>% rename(!!paste0(col_id, "_combined") := !!sym(col_id))
          rows_extrapolate <- merge(rows_extrapolate, rows_ext, by = paste0(col_id, "_combined"))
        } else {
          rows_extrapolate <- data.frame()
        }

        # Interpolate
        rows_interpolate <- req_rows[!(cond_match) & !(cond_extrapolate), ]
        rows_interpolate <- merge(rows_interpolate, rename_with(rows, ~paste0(., "_upper"), everything()), by = paste0(col_id, "_upper"))
        rows_interpolate <- merge(rows_interpolate, rename_with(rows, ~paste0(., "_lower"), everything()), by = paste0(col_id, "_lower"))

        rows_interpolate$value <- rows_interpolate[['value_lower']] + (rows_interpolate[[paste0(col_id, "_upper")]] - rows_interpolate[[col_id]]) /
                  (rows_interpolate[[paste0(col_id, "_upper")]]- rows_interpolate[[paste0(col_id, "_lower")]]) * (rows_interpolate[['value_upper']]- rows_interpolate[['value_lower']])

        # Combine into one dataframe and drop unused columns
        rows_to_concat <- list(rows_match, rows_extrapolate, rows_interpolate)
        rows_to_concat <- Filter(function(x) !is.data.frame(x) || nrow(x) > 0, rows_to_concat)
        if (length(rows_to_concat) > 0) {
          rows_append <- bind_rows(rows_to_concat)

          rows_append <- rows_append %>%  select(-any_of(c(paste0(col_id, "_upper"),
                  paste0(col_id, "_lower"),
                  paste0(col_id, "_combined"),
                  "value_upper",
                  "value_lower")))

          # Add to return list
          ret[[i]] <- rows_append
        }
      }

      # Convert return list to dataframe and return
      if (length(ret) > 0) {
        return(bind_rows(ret))

      } else {
        return(df[FALSE, ])  # Empty data frame
      }
    }

  ),

  public = list(
    #' @description Creates a new instance of the PeriodFieldDefinition Class
    #'
    #' @param name Character. Name of the field.
    #' @param description Character. Description of the field
    initialize = function(name, description) {
      super$initialize(
        field_type = 'case',
        name = name,
        description = description,
        dtype = 'float',
        coded = FALSE
      )
    },

    #' @description  Tests if cell is allowed
    #'
    #' @param cell cell to test
    is_allowed = function(cell) {
      return(is_float(cell) || cell == '*')
    }


  )
)

#' @title SourceFieldDefinition
#'
#' @description Class to store Source fields
SourceFieldDefinition <- R6::R6Class("SourceFieldDefinition",
  inherit = AbstractFieldDefinition,



  public = list(
    #' @description Creates a new instance of the SourceFieldDefinition class
    #'
    #' @param name Character. Name of the field.
    #' @param description Character. Description of the field.
    initialize = function(name, description) {
      super$initialize(
        field_type = 'case',
        name= name,
        description = description,
        dtype = 'category',
        coded = FALSE # TODO: Insert list of BibTeX identifiers here.
        )
    }
    )
)

#' @title CustomFieldDefinition
#'
#' @description Class to store Custom fields
CustomFieldDefinition <- R6::R6Class("CustomFieldDefinition",
  inherit = AbstractFieldDefinition,
  public = list(
    #' @field  field_specs
    #' Specs of the field
    field_specs = NULL,
    #' @description Creates a new instance of the CustomFieldDefinition class
    #'
    #' @param field_specs Specs of the custom field
    initialize = function(field_specs) {

    if (!('type' %in% names(field_specs) && is.string(field_specs$type) && field_specs$type %in% c('case', 'component'))) {
    stop("Field type must be provided and equal to 'case' or 'component'.")
    }

    if (!('name' %in% names(field_specs) && is.string(field_specs$name))) {
    stop("Field name must be provided and of type string.")
    }

    if (!('description' %in% names(field_specs) && is.string(field_specs$description))) {
    stop("Field description must be provided and of type string.")
    }

    if (!('coded' %in% names(field_specs) && is.logical(field_specs$coded))) {
    stop("Field coded must be provided and of type bool.")
    }

    if (field_specs$coded && !('codes' %in% names(field_specs) && is.list(field_specs$codes))) {
    stop("Field codes must be provided and contain a list of possible codes.")
    }
    if ('codes' %in% names(field_specs)) {
        x <- field_specs$codes
    } else {
        x <- NULL
    }


    super$initialize(
        field_type=field_specs$type,
        name=field_specs$name,
        description=field_specs$description,
        dtype='category',
        coded=field_specs$coded,
        codes= x
    )

      self$field_specs <- field_specs

    }
  )
)



base_columns <- list(
  'region' = RegionFieldDefinition$new(
    name = 'Region',
    description = 'The region that this value is reported for.'
  ),
  'period' = PeriodFieldDefinition$new(
    name = 'Period',
    description = 'The period that this value is reported for.'
  ),
  'variable' = VariableDefinition$new(
    name = 'Variable',
    description = 'The reported variable.',
    required = TRUE
  ),
  'reference_variable' = VariableDefinition$new(
    name = 'Reference Variable',
    description = 'The reference variable. This is used as an addition to the reported variable to clear, simplified, and transparent data reporting.',
    required = FALSE
  ),
  'value' = ValueDefinition$new(
    name = 'Value',
    description = 'The reported value.',
    required = TRUE
  ),
  'uncertainty' = ValueDefinition$new(
    name = 'Uncertainty',
    description = 'The reported uncertainty.',
    required = FALSE
  ),
  'unit' = UnitDefinition$new(
    name = 'Unit',
    description = 'The reported unit that goes with the reported value.',
    required = TRUE
  ),
  'reference_value' = ValueDefinition$new(
    name = 'Reference Value',
    description = 'The reference value. This is used as an addition to the reported variable to clear, simplified, and transparent data reporting.',
    required = FALSE
  ),
  'reference_unit' = UnitDefinition$new(
    name = 'Reference Unit',
    description = 'The reference unit. This is used as an addition to the reported variable to clear, simplified, and transparent data reporting.',
    required = FALSE
  ),
  'comment' = CommentDefinition$new(
    name = 'Comment',
    description = 'A generic free text field commenting on this entry.',
    required = FALSE
  ),
  'source' = SourceFieldDefinition$new(
    name = 'Source',
    description = 'A reference to the source that this entry was taken from.'
  ),
  'source_detail' = CommentDefinition$new(
    name = 'Source Detail',
    description = 'Detailed information on where in the source this entry can be found.',
    required = TRUE
  )
)


read_fields <- function(variable) {
  fields <- list()
  comments <- list()


  for (database_id in names(databases)) {
    fpath <- file.path(databases[[database_id]], 'fields', paste0(paste(unlist(strsplit(variable, split= "\\|")), collapse = '/'), '.yml'))
    if (file.exists(fpath)) {
      if (dir.exists(fpath)) {
        stop(paste("Expected YAML file, but not a file:", fpath))
      }


      fpathfile <- read_yml_file(fpath)
      for (pair in names(fpathfile)) {
        col_id <- pair
        field_specs <- fpathfile[[pair]]
        if (field_specs['type'] %in% list('case', 'component')) {

            fields[[col_id]] <- CustomFieldDefinition$new(field_specs)
        } else if (field_specs['type'] == 'comment') {

            comments[[col_id]] <- CommentDefinition$new(name=field_specs$name, field_specs$description, required =FALSE)
        }  else {
            stop(sprintf("Unknown field type: %s", col_id))
        }

      }
    # make sure the field ID is not the same as for a base column
      for (col_id in names(fields)) {
        if (col_id %in% base_columns) {
            stop(sprintf("Field ID cannot be equal to a base column ID: %s", col_id))
        }
      }
      }
    }
    return(list(fields= fields, comments= comments))
  }
