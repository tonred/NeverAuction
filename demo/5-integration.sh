export NOT_ELECTOR_PATH="../../build/"
export NOT_ELECTOR_NAME="NeverElectorAuction"
export NOT_ELECTOR_KWARGS=$(python demo/utils/not_elector_kwargs.py)

cd not_oracle/src || exit
pip install -r requirements.txt
./simple_run.sh
cd ../..

# check if auction is created
python demo/utils/auction_info.py
