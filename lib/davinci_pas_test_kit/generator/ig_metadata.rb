module DaVinciPASTestKit
  class Generator
    class IGMetadata
      attr_accessor :ig_version, :groups, :use_case_groups

      def reformatted_version
        @reformatted_version ||= ig_version.delete('.-')
      end

      def ordered_groups
        @ordered_groups ||=
          [patient_group] + non_delayed_groups + delayed_groups
      end

      def patient_group
        @patient_group ||=
          groups.find { |group| group.resource == 'Patient' }
      end

      def delayed_groups
        @delayed_groups ||=
          groups.select(&:delayed?)
      end

      def non_delayed_groups
        @non_delayed_groups ||=
          groups.reject(&:delayed?) - [patient_group]
      end

      def delayed_profiles
        @delayed_profiles ||=
          delayed_groups.map(&:profile_url)
      end

      def add_use_case_groups(id, file_name)
        @use_case_groups ||= []
        @use_case_groups << { id:, file_name: }
      end

      def bundle_groups
        @bundle_groups ||=
          groups.select { |group| group.resource == 'Bundle' }
            .reject { |group| group.profile_name.include?('Base') }
      end

      def claim_groups
        @claim_groups ||=
          groups.select { |group| group.resource == 'Claim' }
            .reject { |group| group.profile_name.include?('Base') }
      end

      def postprocess_groups(ig_resources)
        groups.each do |group|
          group.add_delayed_references(delayed_profiles, ig_resources)
        end
      end

      def to_hash
        {
          ig_version:,
          groups: groups.map(&:to_hash)
        }
      end
    end
  end
end
