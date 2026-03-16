#!/bin/zsh

set -euo pipefail

if [[ "$#" -eq 4 ]]; then
  inferno_base_url="${1}"
  suite_id="${2}"
  preset_path="${3}"
  session_path="${4}"
elif [[ "$#" -eq 3 ]]; then
  inferno_base_url="http://localhost:4567"
  suite_id="${1}"
  preset_path="${2}"
  session_path="${3}"
else
  echo "usage: $0 [inferno_base_url] suite_id preset_path session_path" >&2
  exit 1
fi

tmp_dir="$(mktemp -d /tmp/pas-ms.XXXXXX)"
submit_dir="$tmp_dir/submit"
inquire_dir="$tmp_dir/inquire"
mkdir -p "$submit_dir" "$inquire_dir"
trap 'rm -rf "$tmp_dir"' EXIT

env -u RUBYOPT -u BUNDLE_GEMFILE ruby -rjson -e '
  file, submit_name, inquire_name, submit_out, inquire_out = ARGV
  erb_tag = "<%= Inferno::Application['\''base_url'\''] %>"
  text = File.read(file).gsub(erb_tag, "http://example.invalid")
  config = JSON.parse(text)
  inputs = config.fetch("inputs")

  write_payloads = lambda do |input_name, output_dir|
    raw_payload = inputs.find { |input| input["name"] == input_name }&.fetch("value")
    raise "Missing input #{input_name}" if raw_payload.nil?

    payloads = JSON.parse(raw_payload)
    payloads = [payloads] unless payloads.is_a?(Array)
    payloads.each_with_index do |payload, index|
      File.write(File.join(output_dir, format("%03d.json", index)), JSON.pretty_generate(payload))
    end
  end

  write_payloads.call(submit_name, submit_out)
  write_payloads.call(inquire_name, inquire_out)
' \
  "$preset_path" \
  must_support_pa_submit_request_payload \
  must_support_pa_inquire_request_payload \
  "$submit_dir" \
  "$inquire_dir"

submit_url="${inferno_base_url}/custom/${suite_id}/${session_path}/fhir/Claim/\$submit"
inquire_url="${inferno_base_url}/custom/${suite_id}/${session_path}/fhir/Claim/\$inquire"
resume_url="${inferno_base_url}/custom/${suite_id}/resume_pass?token=${session_path}"

for submit_payload in "$submit_dir"/*.json; do
  curl --fail --silent --show-error -o /dev/null \
    -X POST \
    -H 'Content-Type: application/fhir+json' \
    --data @"$submit_payload" \
    "$submit_url"
done

for inquire_payload in "$inquire_dir"/*.json; do
  curl --fail --silent --show-error -o /dev/null \
    -X POST \
    -H 'Content-Type: application/fhir+json' \
    --data @"$inquire_payload" \
    "$inquire_url"
done

curl --fail --silent --show-error -o /dev/null "$resume_url"
