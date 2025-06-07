# frozen_string_literal: true

require_relative "../../../spec_helper"

RSpec.describe Lti::Pns::LtiResourceCopyNoticeBuilder, type: :model do
  let(:account) { account_model }
  let(:developer_key) do
    dk = DeveloperKey.new(
      scopes: ["https://purl.imsglobal.org/spec/lti/scope/noticehandlers"],
      account: account
    )
    dk.save!
    dk
  end
  let(:tool) do
    ContextExternalTool.new(
      name: "Test Tool",
      url: "https://www.test.tool.com",
      consumer_key: "key",
      shared_secret: "secret",
      settings: { "platform" => "canvas" },
      account:,
      developer_key:,
      root_account: account
    )
  end

  let(:source_course) { course_model(account:) }
  let(:target_course) { course_model(account:) }
  let(:params) do
    {
      source_context: source_course,
      source_resource_id: "src123",
      target_context: target_course,
      target_resource_id: "tgt456",
      copied_at: copied_at
    }
  end
  let(:copied_at) { Time.now.utc.iso8601 }

  describe "#initialize" do
    it "raises an error if required params are missing" do
      expect { described_class.new(params.except(:source_context)) }.to raise_error(ArgumentError)
      expect { described_class.new(params.except(:copied_at)) }.to raise_error(ArgumentError)
    end
  end

  describe "#build" do
    subject { described_class.new(params).build(tool) }

    before do
      allow(LtiAdvantage::Messages::JwtMessage).to receive(:create_jws).and_return("signed_jwt")
      allow(Rails.application.routes.url_helpers).to receive(:lti_notice_handlers_url).and_return("https://example.com/notice_handler")
    end

    it "returns a notice" do
      Timecop.freeze do
        expect(subject).to eq({ jwt: "signed_jwt" })
        expect(LtiAdvantage::Messages::JwtMessage).to have_received(:create_jws).with(
          hash_including(
            "https://purl.imsglobal.org/spec/lti/claim/notice" => {
              "id" => anything,
              "timestamp" => copied_at,
              "type" => "LtiResourceCopyNotice"
            },
            "https://purl.imsglobal.org/spec/lti/claim/context" => hash_including(id: target_course.lti_context_id),
            "https://purl.imsglobal.org/spec/lti/claim/resource_id" => "tgt456",
            "https://purl.imsglobal.org/spec/lti/claim/origin_resource_ids" => [
              {
                context: source_course.lti_context_id,
                resource_id: "src123"
              }
            ]
          ),
          anything
        )
      end
    end
  end
end
