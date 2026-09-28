RSpec.describe DaVinciPASTestKit::ReferencedResourcePresenceValidation do
  let(:test_instance) do
    Class.new { include DaVinciPASTestKit::ReferencedResourcePresenceValidation }.new
  end

  describe '#extract_base_url' do
    it 'returns an empty string for a blank url' do
      expect(test_instance.extract_base_url(nil)).to eq('')
      expect(test_instance.extract_base_url('')).to eq('')
    end

    it 'returns an empty string when the url has no scheme or host' do
      expect(test_instance.extract_base_url('/Claim/123')).to eq('')
    end

    it 'strips the resource type and id from an absolute url' do
      url = 'http://example.com/fhir/Claim/123'
      expect(test_instance.extract_base_url(url)).to eq('http://example.com/fhir')
    end

    it 'strips the resource type and id when the base path has multiple segments' do
      url = 'https://example.com/fhir/r4/Patient/abc'
      expect(test_instance.extract_base_url(url)).to eq('https://example.com/fhir/r4')
    end

    it 'preserves an explicit port by using uri.authority instead of uri.host' do
      url = 'http://example.com:8080/fhir/Claim/123'
      expect(test_instance.extract_base_url(url)).to eq('http://example.com:8080/fhir')
    end

    it 'preserves an explicit port on https urls as well' do
      url = 'https://example.com:8443/fhir/Claim/123'
      expect(test_instance.extract_base_url(url)).to eq('https://example.com:8443/fhir')
    end
  end

  describe '#absolute_url' do
    it 'returns nil for a blank reference' do
      expect(test_instance.absolute_url(nil, 'http://example.com/fhir')).to be_nil
      expect(test_instance.absolute_url('', 'http://example.com/fhir')).to be_nil
    end

    it 'returns the reference unchanged when it is a urn:uuid' do
      reference = 'urn:uuid:11111111-1111-4111-8111-111111111111'
      expect(test_instance.absolute_url(reference, 'http://example.com/fhir')).to eq(reference)
    end

    it 'returns the reference unchanged when it is already absolute' do
      reference = 'http://other-server.com/fhir/Patient/1'
      expect(test_instance.absolute_url(reference, 'http://example.com/fhir')).to eq(reference)
    end

    it 'returns the reference unchanged when base_url is blank' do
      expect(test_instance.absolute_url('Patient/1', '')).to eq('Patient/1')
    end

    it 'joins a relative reference to the base url' do
      expect(test_instance.absolute_url('Patient/1', 'http://example.com/fhir')).to eq('http://example.com/fhir/Patient/1')
    end

    it 'joins a relative reference to a base url that includes a port' do
      expect(test_instance.absolute_url('Patient/1', 'http://example.com:8080/fhir'))
        .to eq('http://example.com:8080/fhir/Patient/1')
    end
  end

  describe '#check_presence_of_referenced_resources' do
    let(:base_url) { 'http://example.com:8080/fhir' }

    def entry(full_url, resource)
      FHIR::Bundle::Entry.new(fullUrl: full_url, resource:)
    end

    it 'returns an empty array when the target resource is blank' do
      expect(test_instance.check_presence_of_referenced_resources(nil, base_url, [])).to eq([])
    end

    it 'returns no errors when a referenced resource is present exactly once' do
      patient = FHIR::Patient.new(id: 'pat-1')
      patient_entry = entry("#{base_url}/Patient/pat-1", patient)
      claim = FHIR::Claim.new(id: 'claim-1', patient: { reference: "#{base_url}/Patient/pat-1" })
      claim_entry = entry("#{base_url}/Claim/claim-1", claim)

      errors = test_instance.check_presence_of_referenced_resources(claim, base_url, [claim_entry, patient_entry])

      expect(errors).to be_empty
    end

    it 'returns an error when a referenced resource is missing from the bundle' do
      claim = FHIR::Claim.new(id: 'claim-1', patient: { reference: "#{base_url}/Patient/missing" })
      claim_entry = entry("#{base_url}/Claim/claim-1", claim)

      errors = test_instance.check_presence_of_referenced_resources(claim, base_url, [claim_entry])

      expect(errors.join).to include('SHALL appear exactly once in the Bundle, but found 0')
    end

    it 'returns an error when a referenced resource appears more than once' do
      patient = FHIR::Patient.new(id: 'pat-1')
      patient_entry_a = entry("#{base_url}/Patient/pat-1", patient)
      patient_entry_b = entry("#{base_url}/Patient/pat-1", patient)
      claim = FHIR::Claim.new(id: 'claim-1', patient: { reference: "#{base_url}/Patient/pat-1" })
      claim_entry = entry("#{base_url}/Claim/claim-1", claim)

      errors = test_instance.check_presence_of_referenced_resources(
        claim, base_url, [claim_entry, patient_entry_a, patient_entry_b]
      )

      expect(errors.join).to include('SHALL appear exactly once in the Bundle, but found 2')
    end

    it 'skips ClaimResponse.request since it is a back-reference to the submitted Claim' do
      claim_response = FHIR::ClaimResponse.new(id: 'cr-1', request: { reference: "#{base_url}/Claim/missing" })
      claim_response_entry = entry("#{base_url}/ClaimResponse/cr-1", claim_response)

      errors = test_instance.check_presence_of_referenced_resources(claim_response, base_url, [claim_response_entry])

      expect(errors).to be_empty
    end

    it 'skips Claim.related when skip_claim_related is true' do
      grandparent_url = "#{base_url}/Claim/missing-grandparent"
      claim = FHIR::Claim.new(id: 'claim-2', related: [{ claim: { reference: grandparent_url } }])
      claim_entry = entry("#{base_url}/Claim/claim-2", claim)

      errors = test_instance.check_presence_of_referenced_resources(claim, base_url, [claim_entry],
                                                                    skip_claim_related: true)

      expect(errors).to be_empty
    end

    it 'does not skip Claim.related when skip_claim_related is false' do
      grandparent_url = "#{base_url}/Claim/missing-grandparent"
      claim = FHIR::Claim.new(id: 'claim-2', related: [{ claim: { reference: grandparent_url } }])
      claim_entry = entry("#{base_url}/Claim/claim-2", claim)

      errors = test_instance.check_presence_of_referenced_resources(claim, base_url, [claim_entry],
                                                                    skip_claim_related: false)

      expect(errors.join).to include('SHALL appear exactly once in the Bundle, but found 0')
    end

    it 'returns a fresh array on separate calls rather than accumulating across calls' do
      claim_with_missing_ref = FHIR::Claim.new(id: 'claim-1', patient: { reference: "#{base_url}/Patient/missing" })
      claim_entry = entry("#{base_url}/Claim/claim-1", claim_with_missing_ref)

      test_instance.check_presence_of_referenced_resources(claim_with_missing_ref, base_url, [claim_entry])
      second_errors = test_instance.check_presence_of_referenced_resources(FHIR::Claim.new(id: 'claim-2'), base_url,
                                                                           [])

      expect(second_errors).to be_empty
    end
  end
end
