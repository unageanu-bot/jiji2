import React                  from "react"
import MUI                    from "material-ui"
import AbstractComponent      from "../widgets/abstract-component"

const RaisedButton = MUI.RaisedButton;

export default class SettingFinishedView extends AbstractComponent {

  constructor(props) {
    super(props);
    this.state = {
    };
  }

  render() {
    return (
      <div className="setting-finished-view">
        <h3>完了</h3>
        <div className="description">
          すべての設定が完了しました。
        </div>
        <ul className="description">
          <li>システムの詳しい使い方は<a href="" target="_blank">こちら</a>をご覧ください。</li>
          <li>
            モバイル版アプリも、ぜひご利用ください。
          </li>
        </ul>
        <div className="buttons">
          <RaisedButton
            label="利用を開始する"
            onClick={() => this.props.model.exit()}
            primary={true}
            style={{width:"300px", height: "50px"}}
          />
        </div>
      </div>
    );
  }
}
SettingFinishedView.propTypes = {
  model: React.PropTypes.object
};
SettingFinishedView.defaultProps = {
  model: null
};
