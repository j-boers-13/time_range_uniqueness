# frozen_string_literal: true

require 'digest'

module TimeRangeUniqueness
  MAX_IDENTIFIER_LENGTH = 63

  module ConstraintNaming
    module_function

    def default_constraint_name(table, scope_columns, time_range_column)
      name = "exclude_#{table}_on_#{[scope_columns, time_range_column].flatten.join('_')}"
      return name if name.length <= MAX_IDENTIFIER_LENGTH

      digest = Digest::SHA256.hexdigest(name)[0, 10]
      "#{name[0, MAX_IDENTIFIER_LENGTH - digest.length - 1]}_#{digest}"
    end
  end
end
