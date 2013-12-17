require "spec_helper"

describe QBIntegration::ProductImporter do
  subject do
    described_class.new(product_message, config)
  end

  let(:config) { Factories.config }

  context "error handling" do
    let(:product_message) do
      {
        message: "product:new",
        message_id: 123,
        payload: {
          product: Factories.product
        }
      }.with_indifferent_access
    end

    context "missing parameters" do
      let(:config) {{}}

      it "generates an error notification" do
        VCR.use_cassette "product_importer/missing_config" do
          code, notification = subject.import

          expect(code).to eq 200
          expect(notification["notifications"].count).to eq 1
          expect(notification["notifications"][0]["subject"]).to include "key not found"
        end
      end
    end

    context "account not found" do
      let(:config) do
        c = Factories.config
        c["quickbooks.income_account"] = "Not to be found"
        c
      end

      it "generates an error notification" do
        VCR.use_cassette "product_importer/missing_account" do
          code, notification = subject.import

          expect(code).to eq 200
          expect(notification["notifications"].count).to eq 1
          expect(notification["notifications"][0]["subject"]).to include "No Account"
        end
      end
    end
  end

  context "product already exists" do
    let(:product_message) do
      {
        message: "product:new",
        message_id: 123,
        payload: {
          product: Factories.product
        }
      }.with_indifferent_access
    end

    it "updates the product" do
      VCR.use_cassette "product_importer/product_update_variants" do
        code, notification = subject.import

        expect(code).to eq 200
        expect(notification["notifications"].count).to eq 3
        expect(notification["notifications"][0]["subject"]).to include "Updated product with Sku = ROR-TS"
        expect(notification["notifications"][1]["subject"]).to include "Updated product with Sku = ROR-TS-v-1"
        expect(notification["notifications"][2]["subject"]).to include "Updated product with Sku = ROR-TS-v-2"
      end
    end
  end

  context "products doesnt exist" do
    context "product with variants" do
      let(:product_message) do
        {
          message: "product:new",
          message_id: 123,
          payload: {
            product: Factories.product('family-guy')
          }
        }.with_indifferent_access
      end

      it "creates the product" do
        VCR.use_cassette "product_importer/product_new_variants" do
          code, notification = subject.import

          expect(code).to eq 200
          expect(notification["notifications"].count).to eq 3
          expect(notification["notifications"][0]["subject"]).to include "family-guy"
          expect(notification["notifications"][1]["subject"]).to include "family-guy-v-1"
          expect(notification["notifications"][2]["subject"]).to include "family-guy-v-2"
        end
      end
    end

    context "product without variants" do
      let(:product_message) do
        {
          message: "product:new",
          message_id: 123,
          payload: {
            product: Factories.product_without_variants('nine-inch-nails-cd')
          }
        }.with_indifferent_access
      end

      it "creates the product" do
        VCR.use_cassette "product_importer/product_new_without_variants" do
          code, notification = subject.import

          expect(code).to eq 200
          expect(notification["notifications"][0]["subject"]).to include "Imported product"
        end
      end
    end
  end
end
