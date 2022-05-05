echo "Don't forget to set DevNet network in locklift.config.js"
./demo/1-init.sh
./demo/2-build.sh
./demo/3-test.sh
npm run 1-deploy-account
npm run 2-deploy-never-root
npm run 5-deploy-auction-root-demo
