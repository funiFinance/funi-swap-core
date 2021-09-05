pragma solidity =0.5.16;

import "./interfaces/IFuniSwapFactory.sol";
import "./FuniSwapPair.sol";

contract FuniSwapFactory is IFuniSwapFactory {
    bytes32 public constant INIT_CODE_PAIR_HASH = keccak256(abi.encodePacked(type(FuniSwapPair).creationCode));

    address public feeTo;
    address public feeToSetter;

    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    bool public needAdminApproval;

    address public admin; // need admin approval to create a pool at the beginning

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    modifier onlyAdmin(){
        require(admin == msg.sender, "FuniSwap: no permission");
        _;
    }
    constructor(address _feeToSetter) public {
        feeToSetter = _feeToSetter;
        needAdminApproval = true;
        admin = msg.sender;
    }

    function setAdminApproval() external onlyAdmin{
        if(needAdminApproval == true){
            needAdminApproval = false;
        }
    }

    function changeAdmin(address _newAd) external onlyAdmin{
        require(_newAd != address(0));
        admin = _newAd;
    }

    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB, uint _startingSwapTime) external returns (address pair) {
        uint startingSwapTime;
        if(needAdminApproval == true){
            require(admin == tx.origin, "FuniSwap: no permission");
            startingSwapTime = _startingSwapTime;
        }
        else{
            startingSwapTime = now;
        }

        require(tokenA != tokenB, 'FuniSwap: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'FuniSwap: ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'FuniSwap: PAIR_EXISTS'); // single check is sufficient
        bytes memory bytecode = type(FuniSwapPair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        IFuniSwapPair(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external {
        require(msg.sender == feeToSetter, 'FuniSwap: FORBIDDEN');
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, 'FuniSwap: FORBIDDEN');
        feeToSetter = _feeToSetter;
    }
}