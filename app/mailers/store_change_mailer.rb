class StoreChangeMailer < ApplicationMailer
  # Alerts that these SkinItems just left the CS2 in-game store — the item was
  # pulled directly, or the case/capsule it unboxes from was discontinued.
  def discontinued(skin_item_ids)
    @skin_items = SkinItem.includes(:skin).where(id: skin_item_ids).order(:name)
    return if @skin_items.empty?

    count = @skin_items.size
    mail(
      to: notify_address,
      subject: "CS2 store: #{count} item#{'s' if count != 1} discontinued"
    )
  end

  private

  def notify_address
    ENV["NOTIFY_EMAIL"].presence || ENV["GMAIL_USERNAME"]
  end
end
