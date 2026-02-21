#import libraries
import kagglehub
import os
import pandas as pd
import sqlalchemy as sal

#Download latest version
path = kagglehub.dataset_download("shivamb/netflix-shows")

print("Path to dataset files:", path)
#checks name of the path

#Importing the csv file into a Data frame
df = pd.read_csv(os.path.join(path, 'netflix_titles.csv'))

#Sanity checks
print("Shape:", df.shape)
print("\nColumns:", df.columns)
print("\nMissing values:")
print(df.isna().sum())
print("\nData types:")
print(df.dtypes)

#Load into MYSQL
engine = sal.create_engine( "mysql+pymysql://username:password@localhost/netflix_db")
conn = engine.connect()
df.to_sql('netflix_raw', con = conn, index = False, if_exists = 'append')
conn.close()
