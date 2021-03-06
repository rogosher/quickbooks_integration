require 'spec_helper'

module QBIntegration
  module Service
    describe SalesReceipt do
      let(:order) { Factories.order }
      let(:payload) do
        order[:placed_on] = Time.now.to_s(:iso8601)

        {
          "order" => order
        }.with_indifferent_access
      end

      let(:config) do
        {
          'quickbooks_realm' => "1081126165",
          'quickbooks_access_token' => "123",
          'quickbooks_access_secret' => "OLDrgtlzvffzyH1hMDtW5PF6exayVlaCDxFjMd0o",
          "quickbooks_payment_method_name" => [{ "visa" => "Discover" }],
          'quickbooks_account_name' => "Inventory Asset",
          'quickbooks_deposit_to_account_name' => "Inventory Asset",
          "quickbooks_web_orders_user" => "false"
        }
      end


      subject { SalesReceipt.new(config, payload) }

      it "persist new sales receipt" do
        VCR.use_cassette("sales_receipt/persist_new_receipt") do
          sales_receipt = subject.create
          expect(sales_receipt.doc_number).to eq Factories.order["number"]
        end
      end

      it "finds by order number" do
        VCR.use_cassette("sales_receipt/find_by_order_number") do
          sales_receipt = subject.find_by_order_number
          expect(sales_receipt.doc_number).to eq Factories.order["number"]
        end
      end

      it "updates existing sales receipt" do
        payload[:order][:email] = "updated@mail.com"

        VCR.use_cassette("sales_receipt/sync_updated_order") do
          sales_receipt = subject.update subject.find_by_order_number
          expect(sales_receipt.bill_email.address).to eq "updated@mail.com"
        end
      end

      it "appends ship tracking number if available on update" do
        payload[:order][:shipments].first[:tracking] = "IamAString"
        VCR.use_cassette("sales_receipt/sync_updated_order_with_tracking_number") do
          sales_receipt = subject.update subject.find_by_order_number
          expect(sales_receipt.tracking_num).to match "IamAString"
        end
      end
    end
  end
end
