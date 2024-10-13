defmodule Newsticker.Ticker.Item do
  use Ash.Resource,
    otp_app: :newsticker,
    domain: Newsticker.Ticker,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "ticker_item"
    repo Newsticker.Repo
  end

  actions do
    defaults [:create, :read, :update, :destroy]
  end

  attributes do
    uuid_v7_primary_key :id

    attribute :value, :string do
      allow_nil? false
      public? true
    end

    timestamps()
  end

  relationships do
    belongs_to :source, Newsticker.Ticker.Source
  end
end
