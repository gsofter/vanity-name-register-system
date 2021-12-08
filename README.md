# Vanity Name Register System

### Main functions

- preRegister: Save item to mapping with structure of hash(address, name) => timestamp

- register: Register & lock balance for available pre registerd lists

- renew: Increase expiration time by adding lockTime

- withdrawLockedBalance: width available locked balance

Try running some of the following tasks:

### How to prevent frontrun

```
To register name, user name to preRegister it's hash([userAddress, name]).

At the registeration step, if hash(userAddress, name) is pre registered, user can register the name, other wise the transaction would fail.

To prevent malcious user to frontrun preRegister and register together before the user's register transaction, I've added cooldown time which indicates the minimum duration between user's preRegister request and register request.

In conclusion, to register name, user must run 2 transactions: preRegister and register.
And register must be called at least cool down time has passed.
```

```shell
npx hardhat accounts
npx hardhat compile
npx hardhat clean
npx hardhat test
npx hardhat node
npx hardhat help
REPORT_GAS=true npx hardhat test
npx hardhat coverage
npx hardhat run scripts/deploy.ts
TS_NODE_FILES=true npx ts-node scripts/deploy.ts
npx eslint '**/*.{js,ts}'
npx eslint '**/*.{js,ts}' --fix
npx prettier '**/*.{json,sol,md}' --check
npx prettier '**/*.{json,sol,md}' --write
npx solhint 'contracts/**/*.sol'
npx solhint 'contracts/**/*.sol' --fix
```

# Etherscan verification

To try out Etherscan verification, you first need to deploy a contract to an Ethereum network that's supported by Etherscan, such as Ropsten.

In this project, copy the .env.example file to a file named .env, and then edit it to fill in the details. Enter your Etherscan API key, your Ropsten node URL (eg from Alchemy), and the private key of the account which will send the deployment transaction. With a valid .env file in place, first deploy your contract:

```shell
hardhat run --network ropsten scripts/sample-script.ts
```

Then, copy the deployment address and paste it in to replace `DEPLOYED_CONTRACT_ADDRESS` in this command:

```shell
npx hardhat verify --network ropsten DEPLOYED_CONTRACT_ADDRESS "Hello, Hardhat!"
```

# Performance optimizations

For faster runs of your tests and scripts, consider skipping ts-node's type checking by setting the environment variable `TS_NODE_TRANSPILE_ONLY` to `1` in hardhat's environment. For more details see [the documentation](https://hardhat.org/guides/typescript.html#performance-optimizations).
