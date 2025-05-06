# 0.13.0

This incorporates SMART and UDAP authentication, Subscriptions, requirements documentation, and Inferno Core updates.

* FI-3828: Add PAS Server verifies_requirements by @elsaperelli in https://github.com/inferno-framework/davinci-pas-test-kit/pull/29
* Add verifies_requirements to the generator by @elsaperelli in https://github.com/inferno-framework/davinci-pas-test-kit/pull/32
* FI-3625: Incorporate subscriptions into server suite by @tstrass in https://github.com/inferno-framework/davinci-pas-test-kit/pull/31
* Client auth by @karlnaden in https://github.com/inferno-framework/davinci-pas-test-kit/pull/27
* Remove client verifies_requirements from server tests by @elsaperelli in https://github.com/inferno-framework/davinci-pas-test-kit/pull/34
* FI-3813: Use core MustSupport features by @dehall in https://github.com/inferno-framework/davinci-pas-test-kit/pull/33
* FI-4053: Suite options for client auth by @karlnaden in https://github.com/inferno-framework/davinci-pas-test-kit/pull/36

# 0.12.2

* FI-3818: Add verifies_requirements to client suite by @elsaperelli in https://github.com/inferno-framework/davinci-pas-test-kit/pull/28
* Upgrade Subscriptions Test Kit for AuthInfo and endpoint URL bug fix by @tstrass in https://github.com/inferno-framework/davinci-pas-test-kit/pull/30

# 0.12.1

* Add Client Subscriptions tests by @karlnaden in https://github.com/inferno-framework/davinci-pas-test-kit/pull/23


# 0.12.0

### Breaking Changes by @vanessuniq in https://github.com/inferno-framework/davinci-pas-test-kit/pull/24:
* **Ruby Version Update:** Upgraded Ruby to `3.3.6`.
* **Inferno Core Update:** Bumped to version `0.6`.
* **Gemspec Updates:**
  * Switched to `git` for specifying files.
  * Added `presets` to the gem package.
  * Updated any test kit dependencies
* **Test Kit Metadata:** Implemented Test Kit metadata for Inferno Platform.
* **Environment Updates:** Updated Ruby version in the Dockerfile and GitHub Actions workflow.


# 0.11.1

* FI-3301: SuiteEndpoints by @tstrass in https://github.com/inferno-framework/davinci-pas-test-kit/pull/21


# 0.11.0

* Auth info by @vanessuniq in https://github.com/inferno-framework/davinci-pas-test-kit/pull/17
* FI-3279: PAS Fix Limitation Documentation by @degradification in https://github.com/inferno-framework/davinci-pas-test-kit/pull/18
* FI-3410: Update inferno core requirement by @Jammjammjamm in https://github.com/inferno-framework/davinci-pas-test-kit/pull/19

# 0.10.1

* FI-2970: Fix inquiry Response Must Support Test by @vanessuniq in https://github.com/inferno-framework/davinci-pas-test-kit/pull/12
* Create unique identifier for pended test wait continuation by @karlnaden in https://github.com/inferno-framework/davinci-pas-test-kit/pull/15
* Documentation pointers to known validator errors due to spec issues by @karlnaden in https://github.com/inferno-framework/davinci-pas-test-kit/pull/14
* Dependency Updates 2024-07-03 by @Jammjammjamm in https://github.com/inferno-framework/davinci-pas-test-kit/pull/9

# 0.10.0

* FI-2701: Migrate to HL7 validator wrapper by @dehall in https://github.com/inferno-framework/davinci-pas-test-kit/pull/4

# 0.9.3

* More gracefully handle missing claim and missing fullUrl by @tstrass in https://github.com/inferno-framework/davinci-pas-test-kit/pull/3
* Dependency Updates 2024-06-05 by @Jammjammjamm in https://github.com/inferno-framework/davinci-pas-test-kit/pull/5
* Add client preset by @tstrass in https://github.com/inferno-framework/davinci-pas-test-kit/pull/6

# 0.9.2

* Patch version bump

# 0.9.1

* Split out suite descriptions to files for linking from other contexts.
* Clarified user input validation tests through additional documentation.
* Clarified the unimplemented stub tests that will check the status of the claim indicated in the ClaimResponse.
* Split out the unimplemented stub test for notifications of an update to a pended claim.
* Updated operation descriptions.

# 0.9.0

* Initial public release.