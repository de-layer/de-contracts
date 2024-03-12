import assert from 'assert';

import { type DeployFunction } from 'hardhat-deploy/types';

const contractName = 'DeLayerAdapter';

const deploy: DeployFunction = async (hre) => {
    const { getNamedAccounts, deployments } = hre;

    const { deploy } = deployments;
    const { deployer } = await getNamedAccounts();

    assert(deployer, 'Missing named deployer account');
    assert(hre.network.config.chainId === 1, 'This deployment script is only available for ETH')

    console.log(`Network: ${hre.network.name}`);
    console.log(`Deployer: ${deployer}`);

    const endpointV2Deployment = await hre.deployments.get('EndpointV2');

    const { address } = await deploy(contractName, {
        from: deployer,
        args: [
            '0xd849882983f1ba8a3c23b16b65bb0173a7f63b63', // token
            endpointV2Deployment.address, // LayerZero's EndpointV2 address
            '0x2512f9b888C76bE41E8Ed499a8C61dFe03DBf518', // owner
        ],
        log: true,
        skipIfAlreadyDeployed: false,
    });

    console.log(`Deployed contract: ${contractName}, network: ${hre.network.name}, address: ${address}`);
};

deploy.tags = [contractName, 'mainnet'];

export default deploy;
