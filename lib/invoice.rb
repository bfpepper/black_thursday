require_relative "../lib/invoice_repo"

class Invoice

  attr_reader :id, :customer_id, :merchant_id, :status, :created_at, :updated_at

  def initialize(row, parent = nil)
    @parent = parent
    @id = row[:id].to_i
    @customer_id = row[:customer_id].to_i
    @merchant_id = row[:merchant_id].to_i
    @status = row[:status].to_sym
    @created_at = Time.strptime(row[:created_at], "%Y-%m-%d")
    @updated_at = Time.strptime(row[:updated_at], "%Y-%m-%d")
  end

  def merchant
    @parent.find_merchant_by_id(self.merchant_id)
  end

  def items
    #collect a list of item_ids from invoice_item_objects
    item_ids = @parent.find_item_ids_on_invoice(self.id)
    #collect a list of items from item_ids
    item_ids.map do |item_id|
      @parent.find_item_by_id(item_id)
    end
end
