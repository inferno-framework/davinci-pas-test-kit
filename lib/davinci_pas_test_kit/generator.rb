require 'inferno/ext/fhir_models'

require_relative 'generator/ig_loader'
require_relative 'generator/ig_metadata_extractor'
require_relative 'generator/use_case_group_generator'
require_relative 'generator/client_must_support_group_generator'
require_relative 'generator/server_must_support_group_generator'
require_relative 'generator/server_suite_generator'
require_relative 'generator/must_support_test_generator'

module DaVinciPASTestKit
  class Generator
    def self.generate
      ig_packages = Dir.glob(File.join(Dir.pwd, 'lib', 'davinci_pas_test_kit', 'igs', '*.tgz'))

      ig_packages.each do |ig_package|
        new(ig_package).generate
      end
    end

    attr_accessor :ig_resources, :ig_metadata, :ig_file_name

    def initialize(ig_file_name)
      self.ig_file_name = ig_file_name
    end

    def generate
      puts "Generating tests for IG #{File.basename(ig_file_name)}"
      load_ig_package
      extract_metadata
      FileUtils.mkdir_p(base_server_output_dir)
      FileUtils.mkdir_p(base_client_output_dir)
      generate_must_support_tests
      generate_use_case_groups
      generate_server_must_support_groups
      generate_client_must_support_groups
      generate_server_suite
      write_profile_metadata
    end

    def load_ig_package
      FHIR.logger = Logger.new(File::NULL)
      self.ig_resources = IGLoader.new(ig_file_name).load
    end

    def extract_metadata
      self.ig_metadata = IGMetadataExtractor.new(ig_resources).extract

      FileUtils.mkdir_p(base_shared_output_dir)
      File.write(File.join(base_shared_output_dir, 'metadata.yml'), YAML.dump(ig_metadata.to_hash))
    end

    def base_shared_output_dir
      File.join(__dir__, 'cross_suite', 'generated', ig_metadata.ig_version)
    end

    def base_server_output_dir
      File.join(__dir__, 'server', 'generated', ig_metadata.ig_version)
    end

    def base_client_output_dir
      File.join(__dir__, 'client', 'generated', ig_metadata.ig_version)
    end

    def generate_must_support_tests
      MustSupportTestGenerator.generate(ig_metadata, base_server_output_dir, base_client_output_dir)
    end

    def generate_use_case_groups
      UseCaseGroupGenerator.generate(ig_metadata, base_server_output_dir)
    end

    def generate_server_must_support_groups
      ServerMustSupportGroupGenerator.generate(ig_metadata, base_server_output_dir)
    end

    def generate_client_must_support_groups
      ClientMustSupportGroupGenerator.generate(ig_metadata, base_client_output_dir)
    end

    def generate_server_suite
      ServerSuiteGenerator.generate(ig_metadata, base_server_output_dir)
    end

    def write_profile_metadata
      # metadata files
      profile_metadata_list = ig_metadata.profiles.select do |profile_metadata|
        MustSupportCheckProfiles.submit_request_profile?(profile_metadata) ||
          MustSupportCheckProfiles.submit_response_profile?(profile_metadata) ||
          MustSupportCheckProfiles.inquire_request_profile?(profile_metadata) ||
          MustSupportCheckProfiles.inquire_response_profile?(profile_metadata)
      end
      profile_metadata_list.each do |profile_metadata|
        metadata_file_dir = File.join(base_shared_output_dir, ig_metadata.snake_case_for_profile(profile_metadata))
        FileUtils.mkdir_p(metadata_file_dir)
        File.write(File.join(metadata_file_dir, 'metadata.yml'), YAML.dump(profile_metadata.to_hash))
      end
    end
  end
end
