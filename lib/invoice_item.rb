require_relative "../lib/invoice_repo"

class InvoiceItem

  attr_reader :id, :item_id, :invoice_id, :quantity, :unit_price, :created_at, :updated_at

  def initialize(row, parent = nil)
    @parent = parent
    @id = row[:id].to_i
    @item_ide = row[:item_id].to_i
    @invoice_id = row[:invoice_id].to_i
    @quantity = row[:quantity].to_f
    @unit_price = BigDecimal.new(row[:unit_price].to_f / 100)
    @created_at = Time.strptime(row[:created_at], "%Y-%m-%d")
    @updated_at = Time.strptime(row[:updated_at], "%Y-%m-%d")
  end

  def unit_price_to_dollars
    @unit_price.to_f
  end

  def item
    @parent.find_item_by_id(self.item_id)
  end
end
