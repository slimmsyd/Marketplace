

import Link from 'next/link'

export default function Nav() { 
    return ( 
        <nav className = "nav">
        <p>Culture Marketplace</p>
        <input></input>
        <div className = "navLinks">
          <Link href = "/"><a className ="aLinks">Home</a></Link>
          <Link href = "/create-item"><a className ="aLinks">Sell Items</a></Link>
          <Link href = "/my-assets"><a className ="aLinks">My Items</a></Link>
          <Link href = "/creator-dashboard"><a className ="aLinks">Items Created</a></Link>
        </div>
      </nav>
  
    )
}