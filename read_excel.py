import pandas as pd
import json

df = pd.read_excel('admin_api.xlsx')
data = df.to_dict(orient='records')

with open('api_dump.json', 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)
