module Html.Svg where

import Data.Maybe (Maybe(..))
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Core as HHC
import Halogen.HTML.Properties as HP
import Halogen.VDom.Types (Namespace(..)) as VDom
import Unsafe.Coerce (unsafeCoerce)

svgElement :: forall r w i. H.ElemName -> Array (HP.IProp r i) -> Array (HH.HTML w i) -> HH.HTML w i
svgElement name props children = HHC.element (Just (VDom.Namespace "http://www.w3.org/2000/svg")) name (unsafeCoerce props) children
