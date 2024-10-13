defmodule Newsticker.Ticker do
  use Ash.Domain

  resources do
    resource Newsticker.Ticker.Source
    resource Newsticker.Ticker.Item
    resource Newsticker.Ticker.Site
  end

  def fetch_sitemap() do
    Req.get!("https://www.der-postillon.com/sitemap.xml").body
    |> Floki.parse_document!()
    |> Floki.find("loc")
    |> Enum.map(&Floki.text/1)
    |> Enum.map(fn loc ->
      Req.get!(loc).body
      |> Floki.parse_document!()
      |> Floki.find("loc")
      |> Enum.map(&Floki.text/1)
    end)
    |> List.flatten()
    |> Enum.filter(&String.contains?(&1, "newsticker"))
    |> Enum.map(&%{site: %{name: "Postillon"}, uri: &1})
    |> Ash.bulk_create!(Newsticker.Ticker.Source, :create, return_errors?: true)
  end
end
