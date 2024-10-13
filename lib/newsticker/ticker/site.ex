defmodule Newsticker.Ticker.Site do
  use Ash.Resource,
    otp_app: :newsticker,
    domain: Newsticker.Ticker,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "ticker_sites"
    repo Newsticker.Repo
  end

  code_interface do
    define :create
    define :read
    define :update
    define :destroy
  end

  actions do
    defaults [:read, :update, :destroy]

    create :create do
      accept :*
      primary? true
    end
  end

  attributes do
    uuid_v7_primary_key :id

    attribute :name, :string do
      allow_nil? false
      public? true
    end

    timestamps()
  end

  identities do
    identity :name, [:name]
  end
  

  relationships do
    has_many :sources, Newsticker.Ticker.Source
  end
end
