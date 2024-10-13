defmodule Newsticker.Ticker.Source do
  use Ash.Resource,
    otp_app: :newsticker,
    domain: Newsticker.Ticker,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "ticker_sources"
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
      primary? true
      argument :site, :map
      accept :*

      upsert? true
      upsert_identity :uri
      upsert_fields {:replace_all_except, :id}

      change manage_relationship(:site,
               type: :append_and_remove,
               use_identities: [:_primary_key, :name]
             )
    end
  end

  attributes do
    uuid_v7_primary_key :id

    attribute :name, :string do
      public? true
    end

    attribute :uri, :string do
      allow_nil? false
      public? true
    end

    timestamps()
  end

  relationships do
    belongs_to :site, Newsticker.Ticker.Site
    has_many :items, Newsticker.Ticker.Item
  end

  identities do
    identity :uri, [:uri]
  end
end

