// eslint-disable-next-line @typescript-eslint/no-var-requires
import { EndpointId } from '@layerzerolabs/lz-definitions';

const mainnetContract = {
    eid: EndpointId.ETHEREUM_V2_MAINNET,
    contractName: 'DeLayerAdapter',
};

const baseContract = {
    eid: EndpointId.BASE_V2_MAINNET,
    contractName: 'DeLayerBridged',
};

export default {
    contracts: [
        {
            contract: mainnetContract,
        },
        {
            contract: baseContract,
        },
    ],
    connections: [
        {
            from: mainnetContract,
            to: baseContract,
        },
        {
            from: baseContract,
            to: mainnetContract,
        },
    ],
};
