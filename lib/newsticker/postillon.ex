defmodule Newsticker.Postillon do
  use Ash.Domain

  resources do
    resource Helpdesk
  end

  def fetch() do
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
  end
end
