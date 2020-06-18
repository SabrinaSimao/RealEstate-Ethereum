// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0 <0.7.0;

contract RealEstate {
    uint public value;
    address payable public seller;
    address payable public buyer;
    bytes32 private assetToken;
    
    enum State {initialState, sellerApproved, finalized, rejected}
    State public state = State.initialState;

    struct assetInfo{
        address owner;
        string zip;
        string city;
        uint price;
        bytes32 assetToken;
    }
    
    
    assetInfo public asset;

    modifier onlyBuyer() {
        require(
            msg.sender == buyer,
            "Only buyer can call this."
        );
        _;
    }

    modifier onlySeller() {
        require(
            msg.sender == seller,
            "Only seller can call this."
        );
        _;
    }

    event Aborted();
    event PurchaseConfirmed();
    event SellerPayed();

    constructor(uint _price, string memory _zip, string memory _city) public {
        seller = msg.sender;
        assetToken = keccak256(abi.encode(_city, _zip, seller));
        asset = assetInfo(msg.sender, _zip, _city, _price*(10**18), assetToken);
    }


    function alterPrice(uint _newPrice) public onlySeller{
        require(state == State.initialState, "Wrong state");
        asset.price = _newPrice*(10**18);
    }


    function sellerApprove() public onlySeller{
        require(state == State.initialState, "Wrong state");
        state = State.sellerApproved;
    }


    /// Confirm the purchase as buyer.
    function buy() public payable
    {
        //seller must have approved
        require(state == State.sellerApproved, "Wrong state");

        //Value must be the same as the asset price
        require(
            msg.sender != seller,
            "seller cannot buy"
        );
        
        require(
            msg.value == asset.price,
            "Value payed different then asset price"
        );

        emit PurchaseConfirmed();
        buyer = msg.sender;
        value = msg.value;

        state = State.finalized;
        paySeller();
    }

    function abortPurchase() public onlySeller {

        //contract cannot have finalized
        require(state != State.finalized, "Cannot abort after finalization");
        emit Aborted();

        state = State.rejected;
    }

    /// This function pays the seller and transfer the asset to the buyer.
    /// instant transaction and payment.
    function paySeller() private
    {
        emit SellerPayed();
        
        //transfer value payed by buyer to the seller
        seller.transfer(value);
        
        //new asset owner is the buyer
        asset.owner = buyer;
    }
}