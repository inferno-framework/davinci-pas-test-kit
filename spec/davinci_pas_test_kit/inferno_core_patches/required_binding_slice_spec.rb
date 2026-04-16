RSpec.describe DaVinciPASTestKit::InfernoCorePatches::RequiredBindingSlice do
  let(:navigation_class) do
    Class.new do
      include Inferno::DSL::FHIRResourceNavigation

      attr_accessor :metadata
    end
  end

  let(:assessment_class) do
    Class.new do
      include Inferno::DSL::MustSupportAssessment

      def config
        OpenStruct.new(options: {})
      end
    end
  end

  let(:metadata) do
    OpenStruct.new(
      must_supports: {
        extensions: [],
        slices: [
          {
            slice_id: 'Coverage.relationship.coding:X12Code',
            slice_name: 'X12Code',
            path: 'relationship.coding',
            discriminator: {
              type: 'requiredBinding',
              path: '',
              values: []
            }
          }
        ],
        elements: [{ path: 'relationship.coding:X12Code.code' }]
      }
    )
  end

  let(:x12_coverage) do
    FHIR::Coverage.new(
      relationship: {
        coding: [
          {
            system: 'https://valueset.x12.org/x217/005010/request/2000D/INS/1/02/00/1069',
            code: '18'
          }
        ]
      }
    )
  end

  let(:non_x12_coverage) do
    FHIR::Coverage.new(
      relationship: {
        coding: [
          {
            system: 'http://example.org/system',
            code: '18'
          }
        ]
      }
    )
  end

  def run_with_metadata(resources)
    assessment_class.new.missing_must_support_elements(resources, nil, metadata:)
  end

  it 'finds a requiredBinding slice child element for X12 codings with blank values' do
    navigator = navigation_class.new
    navigator.metadata = metadata

    expect(navigator.find_a_value_at(x12_coverage, 'relationship.coding:X12Code.code')).to eq('18')
  end

  it 'does not match non-X12 codings when the requiredBinding values are blank' do
    navigator = navigation_class.new
    navigator.metadata = metadata

    expect(navigator.find_a_value_at(non_x12_coverage, 'relationship.coding:X12Code.code')).to be_nil
  end

  it 'treats the X12 slice as present during must support assessment' do
    expect(run_with_metadata([x12_coverage])).to be_empty
  end

  it 'reports the slice and its child element for non-X12 codings' do
    expect(run_with_metadata([non_x12_coverage])).to contain_exactly(
      'relationship.coding:X12Code.code',
      'Coverage.relationship.coding:X12Code'
    )
  end
end
