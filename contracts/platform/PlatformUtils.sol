pragma ton-solidity >= 0.57.0;

pragma AbiHeader time;
pragma AbiHeader expire;
pragma AbiHeader pubkey;

import "./PlatformType.sol";

import "@broxus/contracts/contracts/platform/Platform.sol";


abstract contract PlatformUtils {

    TvmCell public _platformCode;

    function _deAuctionAddress(uint64 nonce) internal view returns (address) {
        TvmCell stateInit = _buildDeAuctionStateInit(nonce);
        return calcAddress(stateInit);
    }

    function _deParticipantAddress(address owner) internal view returns (address) {
        TvmCell stateInit = _buildDeParticipantStateInit(owner);
        return calcAddress(stateInit);
    }

    function _buildDeAuctionStateInit(uint64 nonce) internal view returns (TvmCell) {
        TvmCell initialData = abi.encode(nonce);
        return _buildPlatformStateInit(PlatformType.DE_PARTICIPANT, initialData);
    }

    function _buildDeParticipantStateInit(address owner) internal view returns (TvmCell) {
        TvmCell initialData = abi.encode(owner);
        return _buildPlatformStateInit(PlatformType.DE_PARTICIPANT, initialData);
    }

    function _buildPlatformStateInit(PlatformType platformType, TvmCell initialData) private view returns (TvmCell) {
        return tvm.buildStateInit({
            contr: Platform,
            varInit: {
                root: address(this),
                platformType: uint8(platformType),
                initialData: initialData,
                platformCode: _platformCode
            },
            pubkey: 0,
            code: _platformCode
        });
    }

   function calcAddress(TvmCell stateInit) public pure returns (address) {
       return address(tvm.hash(stateInit));
   }

}
