pragma solidity ^0.4.17;

pragma solidity ^0.4.17;

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
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
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

}
/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {

  using SafeMath for uint256;

  modifier onlyPayloadSize(uint size) {
    assert(msg.data.length == size + 4);
    _;
  }

  mapping(address => uint256) balances;

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }
}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // require (_value <= _allowance);

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) returns (bool) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifing the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {

  address public owner;

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
  }

}

/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */

contract MintableToken is StandardToken, Ownable {

  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;
  mapping (address => bool) public crowdsaleContracts;

  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  modifier onlyCrowdsaleContract() {
    require(crowdsaleContracts[msg.sender]);
    _;
  }

  function addCrowdsaleContract(address _crowdsaleContract) onlyOwner {
    crowdsaleContracts[_crowdsaleContract] = true;
  }

  function deleteCrowdsaleContract(address _crowdsaleContract) onlyOwner {
    require(crowdsaleContracts[_crowdsaleContract]);
    delete crowdsaleContracts[_crowdsaleContract];
  }
  function mint(address _to, uint256 _amount) onlyCrowdsaleContract canMint returns (bool) {

    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(this, _to, _amount);
    return true;
  }

  function finishMinting() onlyCrowdsaleContract returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }

}

contract BSEToken is MintableToken {

  string public constant name = " BLACK SNAIL ENERGY ";

  string public constant symbol = "BSE";

  uint32 public constant decimals = 18;

  event Burn(address indexed burner, uint256 value);

  /**
   * @dev Burns a specific amount of tokens.
   * @param _value The amount of token to be burned.
   */
  function burn(uint256 _value) public {
    require(_value > 0);
    require(_value <= balances[msg.sender]);
    // no need to require value <= totalSupply, since that would imply the
    // sender's balance is greater than the totalSupply, which *should* be an assertion failure

    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply = totalSupply.sub(_value);
    Burn(burner, _value);
  }

}

contract ReentrancyGuard {

  /**
   * @dev We use a single lock for the whole contract.
   */
  bool private rentrancy_lock = false;

  /**
   * @dev Prevents a contract from calling itself, directly or indirectly.
   * @notice If you mark a function `nonReentrant`, you should also
   * mark it `external`. Calling one nonReentrant function from
   * another is not supported. Instead, you can implement a
   * `private` function doing the actual work, and a `external`
   * wrapper marked as `nonReentrant`.
   */
  modifier nonReentrant() {
    require(!rentrancy_lock);
    rentrancy_lock = true;
    _;
    rentrancy_lock = false;
  }
}

contract Stateful {
  enum State {
  Init,
  PreIco,
  salePaused,
  preIcoFinished,
  ICO,
  CrowdsaleFinished
  }
  State public state = State.Init;

  event StateChanged(State oldState, State newState);

  function setState(State newState) internal {
    State oldState = state;
    state = newState;
    StateChanged(oldState, newState);
  }
}


contract FiatContract {
  function ETH(uint _id) constant returns (uint256);
  function USD(uint _id) constant returns (uint256);
  function EUR(uint _id) constant returns (uint256);
  function GBP(uint _id) constant returns (uint256);
  function updatedAt(uint _id) constant returns (uint);
}

contract Crowdsale is Ownable, ReentrancyGuard, Stateful {

  using SafeMath for uint;

  mapping (address => uint) preICOinvestors;
  mapping (address => uint) ICOinvestors;

  BSEToken token;
  uint256 public startICO;
  uint256 public startPreICO;
  uint256 public period;
  uint256 public constant rateCent = 200000000000000000;
  uint256 public constant centSoftCap = 300000000;
  uint256 public constant preICOTokenHardCap = 440000 * 1 ether;
  uint256 public constant ICOTokenHardCap = 1980000 * 1 ether;
  uint256 public collectedCent;
  uint256 day = 86400; // sec in day

  address multisig;

  FiatContract public price = FiatContract(0x2CDe56E5c8235D6360CCbb0c57Ce248Ca9C80909); // mainnet 0x8055d0504666e2B6942BeB8D6014c964658Ca591 testnet 0x2CDe56E5c8235D6360CCbb0c57Ce248Ca9C80909

  modifier saleIsOn() {
    require((state == State.PreIco || state == State.ICO) &&(now < startICO + period || now < startPreICO + period));
    _;
  }

  modifier isUnderHardCap() {
    require(token.totalSupply() < getHardcap());
    _;
  }

  function getHardcap() internal returns(uint256) {
    if (state == State.PreIco) {
      return preICOTokenHardCap;
    }
    else {
      if (state == State.ICO) {
        return ICOTokenHardCap;
      }
    }
  }


  function Crowdsale(address _tokenAddress) {
    token = BSEToken(_tokenAddress);
  }

  // for mint tokens to USD investor
  function usdSale(address _to, uint _valueUSD) onlyOwner  {
    uint256 valueCent = _valueUSD * 100;
    uint256 tokensAmount = rateCent.mul(valueCent);
    collectedCent += valueCent;
    token.mint(_to, tokensAmount);
  }

  function pauseSale() onlyOwner {
    setState(State.salePaused);
  }

  function startPreIco(uint256 _period) onlyOwner {
    startPreICO = now;
    period = _period * day;
    setState(State.PreIco);
  }

  function finishPreIco(uint256 _period) onlyOwner {
    setState(State.preIcoFinished);
    bool isSent = multisig.call.gas(3000000).value(this.balance)();
    require(isSent);
  }

  function startIco(uint256 _period) onlyOwner {
    startICO = now;
    period = _period * day;
    setState(State.ICO);
  }

  function finishICO() onlyOwner {
    setState(State.CrowdsaleFinished);
    bool isSent = multisig.call.gas(3000000).value(this.balance)();
    require(isSent);
    //token.finishMinting();
  }

  function getDouble() nonReentrant {
    uint256 extraTokensAmount;
    if (state == State.ICO) {
      extraTokensAmount = preICOinvestors[msg.sender];
      preICOinvestors[msg.sender] = 0;
      token.mint(msg.sender, extraTokensAmount);
      ICOinvestors[msg.sender] = extraTokensAmount;
    }
    else {
      if (state == State.CrowdsaleFinished) {
        extraTokensAmount = preICOinvestors[msg.sender] + ICOinvestors[msg.sender];
        preICOinvestors[msg.sender] = 0;
        ICOinvestors[msg.sender] = 0;
        token.mint(msg.sender, extraTokensAmount);
      }
    }
  }


  function mintTokens() payable saleIsOn isUnderHardCap nonReentrant {
    uint256 valueWEI = msg.value;
    uint256 priceUSD = price.USD(0);
    uint256 valueCent = valueWEI.div(priceUSD);
    uint256 tokens = rateCent.mul(valueCent);
    uint256 hardcap = getHardcap();
    if (token.totalSupply() + tokens > hardcap) {
      tokens = hardcap.sub(token.totalSupply());
      valueCent = tokens.div(rateCent);
      valueWEI = valueCent.mul(priceUSD);
      uint256 change = msg.value - valueWEI;
      bool isSent = msg.sender.call.gas(3000000).value(change)();
      require(isSent);
    }
    token.mint(msg.sender, tokens);
    collectedCent += valueCent;
    if (state == State.PreIco) {
      preICOinvestors[msg.sender] = tokens;
    }
    else {
      ICOinvestors[msg.sender] = tokens;
    }
  }

  function () payable {
    mintTokens();
  }
}





