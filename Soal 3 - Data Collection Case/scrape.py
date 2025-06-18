import asyncio
import httpx
from bs4 import BeautifulSoup
import polars as pl
from tqdm.asyncio import tqdm
import json

# Set max pages for each level
max_pages = [3, 5, 2, 4, 6] 
BASE_URL = "https://www.fortiguard.com/encyclopedia?type=ips&risk={level}&page={i}"

# Store skipped pages
skipped_pages = {}

# try to get data
async def fetch_page(client, level, page):
    url = BASE_URL.format(level=level, i=page)
    try:
        response = await client.get(url, timeout=10)
        response.raise_for_status()
        return response.text
    except Exception as e:
        print(f"Failed to fetch Level:{level} Page:{page} with Error: {e}")
        skipped_pages.setdefault(level, []).append(page) # If level key doesn’t exist in skipped_pages, create new one and append it
        return None # return none and skip parsing

# parsing data title and link
def parse_page(res):
    soup = BeautifulSoup(res, 'html.parser')

    list_content = soup.find_all('div', onclick=True)

    result = []
    for item in list_content:
        data = dict()
        data['article'] = item.find('div', {'class': 'col-lg', 'style':'word-break:break-all'}).find('b').text
        link = soup.find('div', onclick=True)
        onclick_value = link['onclick']
        url = onclick_value.split('= ')[1].strip("'")
        data['link'] = f"https://www.fortiguard.com{url}"
        result.append(data)

    return result

# fetch pages for each level
async def scrape_level(level, max_page):
    data = []

    async with httpx.AsyncClient() as client:
        tasks = [
            fetch_page(client, level+1, page) for page in range(1, max_page + 1)
        ]
        pages = await tqdm.gather(*tasks, desc=f"Level {level+1}", total=max_page)

    for url in pages:
        if url:
            data.extend(parse_page(url))

    # Save to CSV using Polars
    df = pl.DataFrame(data)
    df.write_csv(f"datasets/forti_lists_{level+1}.csv")


async def main():
    # Run courutines concurrently
    await asyncio.gather(*[
        scrape_level(level, max_pages[level]) for level in range(len(max_pages))
    ])

    # Save skipped pages
    with open("datasets/skipped.json", "w") as f:
        json.dump(skipped_pages, f, indent=4)

    print("\n Scraping complete.")


if __name__ == "__main__":
    asyncio.run(main())
