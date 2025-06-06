# frozen_string_literal: true

module ISO3166
  module CountrySubdivisionMethods
    # @param subdivision_str [String] A subdivision name or code to search for. Search includes translated subdivision names.
    # @return [Subdivision] The first subdivision matching the provided string
    def find_subdivision_by_name(subdivision_str)
      matched_subdivisions = subdivisions.select do |key, value|
        subdivision_str == key || value.match?(subdivision_str)
      end.values

      matched_subdivisions.min_by { |subdivision| subdivision_types.index(subdivision.type) }
    end

    def subdivision_for_string?(subdivision_str)
      subdivisions.transform_values(&:translations)
                  .any? { |key, value| subdivision_str == key || value.values.include?(subdivision_str) }
    end

    #  +true+ if this Country has any Subdivisions.
    def subdivisions?
      !subdivisions.empty?
    end

    # @return [Array<ISO3166::Subdivision>] the list of subdivisions for this Country.
    # :reek:DuplicateMethodCall
    def subdivisions
      @subdivisions ||= if data['subdivisions']
                          ISO3166::Data.create_subdivisions(data['subdivisions'])
                        else
                          ISO3166::Data.subdivisions(alpha2)
                        end
    end

    # @param types [Array<String>] The locale to use for translations.
    # @return [Array<ISO3166::Subdivision>] the list of subdivisions of the given type(s) for this Country.
    def subdivisions_of_types(types)
      subdivisions.select { |_k, value| types.include?(value.type) }
    end

    # @return [Array<String>] the list of subdivision types for this country
    def subdivision_types
      subdivisions.map { |_k, value| value['type'] }.uniq
    end

    # @return [Array<String>] the list of humanized subdivision types for this country. Uses ActiveSupport's `#humanize` if available
    # :reek:DuplicateMethodCall
    def humanized_subdivision_types
      if String.instance_methods.include?(:humanize)
        subdivisions.map { |_k, value| value['type'].humanize.freeze }.uniq
      else
        subdivisions.map { |_k, value| humanize_string(value['type']) }.uniq
      end
    end

    # @param locale [String] The locale to use for translations.
    # @return [Array<Array>] This Country's subdivision pairs of names and codes.
    # :reek:FeatureEnvy
    def subdivision_names_with_codes(locale = :en)
      subdivisions.map { |key, value| [value.translations[locale] || value.name, key] }
    end

    # @param locale [String] The locale to use for translations.
    # @return [Array<String>] A list of subdivision names for this country.
    # :reek:FeatureEnvy
    def subdivision_names(locale = :en)
      subdivisions.map { |_k, value| value.translations[locale] || value.name }
    end

    private

    # :reek:UtilityFunction
    def humanize_string(str)
      (str[0].upcase + str.tr('_', ' ')[1..]).freeze
    end
  end
end
