pragma solidity ^0.4.17;

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Ownable {

  address public owner;

  function Ownable() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
  }
}

contract BlackSnailMarket {

  struct Asset {
    address tokenAddress;
    uint256 rate;
    bool saleIsOn;
  }

  address BSFtokenAddress = 0x0;
  ERC20 BSFtoken = ERC20(BSFtokenAddress);

  mapping (bytes32 => Asset) public tradableTokens;

  function addTokenForSale(address _tokenAddress, bytes32 _ticker, uint256 _rate, bool _saleIsOn) onlyOwner {
    tradableTokens[_ticker].tokenAddress = _tokenAddress;
    tradableTokens[_ticker].rate = _rate;
    tradableTokens[_ticker].saleIsOn = _saleIsOn;
  }

  function deleteToken(bytes32 _ticker) onlyOwner {
    delete tradableTokens[_ticker];
  }

  function pauseTokenSale(bytes32 _ticker) onlyOwner {
    tradableTokens[_ticker].saleIsOn = false;
  }

  function startTokenSale(bytes32 _ticker) onlyOwner {
    tradableTokens[_ticker].saleIsOn = true;
  }

  function changeRate(bytes32 _ticker, _rate) onlyOwner {
    tradableTokens[_ticker].rate = _rate;
  }

  function buyToken(bytes32 _ticker, uint256 amount) public {
    ERC20 token = ERC20(tradableTokens[_ticker].tokenAddress);
    require(token.balanceOf(this) >= amount);
    uint256 valueBSF = amount.div(rate);
    require(BSFtoken.balanceOf(msg.sender) >= valueBSF);
    require(BSFtokenAddress.delegatecall(bytes4(keccak256(transfer(address, uint256))),this,valueBSF));
    require(token.transfer(msg.sender, amount));
  }

}
