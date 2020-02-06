FOLDER=$DATAPATH

touch $DATAPATH/download.lck

rm -r /tmp/databusdump
mkdir /tmp/databusdump

# pull the services
rapper -i turtle -o ntriples https://raw.githubusercontent.com/dbpedia/databus-content/master/services.ttl > /tmp/databusdump/services.ttl

# pull the accounts data
rapper -i turtle -o ntriples https://raw.githubusercontent.com/dbpedia/accounts/master/accounts.ttl > /tmp/databusdump/accounts.ttl

# pull the webids
rapper -i turtle -o ntriples https://raw.githubusercontent.com/dbpedia/accounts/master/accounts.ttl | cut -f1 -d " " | sed 's/<//;s/>//' > /tmp/databusdump/webids
for i in `cat /tmp/databusdump/webids` ; do 
    rapper -i turtle -o ntriples $i >> /tmp/databusdump/webid.ttl
done

# pull the data ids
curl -H "Accept: text/turtle" --data-urlencode "query@./queries/all-datasets.rq"  https://databus.dbpedia.org/repo/sparql > /tmp/databusdump/datasets.ttl

chmod -R 777 /tmp/databusdump
chmod -R 777 ${FOLDER}
rm /tmp/databusdump/webids
mv /tmp/databusdump/* ${FOLDER}


rm $DATAPATH/download.lck

# get the latest dataset
LATEST=$(curl -H "Accept: text/plain" --data-urlencode "query@./queries/latest-dataset.rq"  https://databus.dbpedia.org/repo/sparql | sed 's/\s.*$//')
echo "Latest loaded dataset is $LATEST. Updating query."

QUERY=$(<./queries/new-datasets.rq)
QUERY=${QUERY/DATASET/$LATEST}

while true; do 
    sleep 60
    echo "Checking for new uploads..."
   
    NEW_DATASETS=$(curl -H "Accept: text/plain" --data-urlencode "query=${QUERY}"  https://databus.dbpedia.org/repo/sparql)

    if [ "$NEW_DATASETS" != "# Empty NT" ]; then
        FILE="$FOLDER/$(date +'%T%m%d').nt"
        echo ${NEW_DATASETS} > ${FILE}
        LATEST=$(curl -H "Accept: text/plain" --data-urlencode "query@./queries/latest-dataset.rq"  https://databus.dbpedia.org/repo/sparql | sed 's/\s.*$//')
        echo "New uploads dumped to $FILE"
        echo "Latest loaded dataset is $LATEST. Updating query."
        QUERY=$(<./queries/new-datasets.rq)
        QUERY=${QUERY/DATASET/$LATEST}
    fi
done

